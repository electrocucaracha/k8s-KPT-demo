#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2023
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o pipefail
set -o errexit
#set -o nounset
if [[ ${DEBUG:-false} == "true" ]]; then
    set -o xtrace
fi

# shellcheck source=scripts/_common.sh
source _common.sh
# shellcheck source=./scripts/_utils.sh
source _utils.sh

# NOTE: this env var is used by kind tool
export KIND_CLUSTER_NAME=k8s

function _create_repo {
    curl_gitea_api "org/$1/repos" "{\"name\":\"$2\", \"auto_init\": true, \"default_branch\": \"main\"}"
}

function _create_org {
    curl_gitea_api "orgs" "{\"username\":\"$1\"}"
}

function _create_user {
    user_list=$(exec_gitea admin user list)
    if ! echo "$user_list" | grep -q "$1"; then
        user_create_cmd=(admin user create --username "$1" --password
            "$gitea_default_password" --access-token --email "$1@demo.io")
        [[ ${2:-false} != "true" ]] || user_create_cmd+=(--admin)
        exec_gitea "${user_create_cmd[@]}"
    fi
}

function _wait_gitea_services {
    local max_attempts=5
    for svc in $(sudo docker-compose ps -aq); do
        attempt_counter=0
        until [ "$(sudo docker inspect "$svc" --format='{{.State.Health.Status}}')" == "healthy" ]; do
            [[ ${attempt_counter} -ne ${max_attempts} ]] || error "Max attempts reached for waiting to gitea containers"
            attempt_counter=$((attempt_counter + 1))
            sleep $((attempt_counter * 5))
        done
    done

    attempt_counter=0
    until curl -s http://localhost:3000/api/swagger; do
        [[ ${attempt_counter} -ne ${max_attempts} ]] || error "Max attempts reached for waiting for gitea API"
        attempt_counter=$((attempt_counter + 1))
        sleep $((attempt_counter * 5))
    done
}

function _deploy_porch {
    pushd "$(mktemp -d -t "kpt-porch-XXX")" >/dev/null
    curl -sL https://github.com/kptdev/kpt/releases/download/porch%2Fv0.0.24/deployment-blueprint.tar.gz | tar -xz
    kubectl apply -f .
    popd >/dev/null
}

function _deploy_configsync {
    kubectl wait deployment --for=condition=Available porch-server -n porch-system --timeout=5m
    cat <<EOF | kubectl apply -f -
apiVersion: configmanagement.gke.io/v1
kind: ConfigManagement
metadata:
  name: config-management
spec:
  enableMultiRepo: true
EOF
}

function _create_cluster {
    if ! sudo "$(command -v kind)" get clusters | grep -e "$KIND_CLUSTER_NAME"; then
        sudo -E kind create cluster
        mkdir -p "$HOME/.kube"
        sudo chown -R "$USER": "$HOME/.kube"
        sudo -E kind get kubeconfig | tee "$HOME/.kube/config"
    fi
}

function main {
    _create_cluster
    _deploy_porch
    _deploy_configsync

    # Gitea configuration
    if [ "${CODESPACE_NAME-}" ]; then
        gitea_domain="$CODESPACE_NAME-3000.preview.app.github.dev"
        sed -i "s|ROOT_URL .*|ROOT_URL = https://${gitea_domain}/|g" ./gitea/app.ini
    fi
    sudo docker-compose up -d
    _wait_gitea_services

    # NOTE: The first gitea user created won't be forced to change the password
    _create_user "$gitea_admin_account" true
    _create_org "$gitea_org"
    for repo in "${gitea_repos[@]}"; do
        _create_repo "$gitea_org" "$repo"
    done
}

if [[ ${__name__:-"__main__"} == "__main__" ]]; then
    main
fi
