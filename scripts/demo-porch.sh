#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o pipefail
set -o errexit
set -o nounset
[[ ${DEBUG:-false} != "true" ]] || set -o xtrace

# shellcheck source=scripts/_common.sh
source _common.sh

echo "Initiate a Porch demo using a public base package."
trap 'echo "Demo completed."' EXIT

# List repositories
kubectl get repositories.config.porch.kpt.dev

read -n 1 -r -p "Sample and local repositories registration."

# Register sample repository
kpt alpha repo register --namespace default https://github.com/GoogleContainerTools/kpt-samples.git

# Register local repository
for repo in "${gitea_repos[@]}"; do
    kpt alpha repo register \
        --namespace default \
        --name "$repo" \
        --repo-basic-username="$gitea_admin_account" \
        --repo-basic-password="$gitea_default_password" \
        --deployment "http://$(ip route get 8.8.8.8 | grep "^8." | awk '{ print $7 }'):3000/$gitea_org/$repo.git"
done

# List repositories
kubectl get repositories.config.porch.kpt.dev

read -n 1 -r -p "Get a package revision list."
# List package revisions
kpt alpha rpkg get

read -n 1 -r -p "Clone basens package to create a istions package."

# Clone an upstream package to create a downstream package
kpt alpha rpkg clone \
    "$(kpt alpha rpkg get --name basens --revision v0 -o jsonpath='{.metadata.name}')" \
    istions --repository=deployments --namespace default

# Confirm the package revision was created
kpt alpha rpkg get --name istions

read -n 1 -r -p "Pull the istions package locally for modifications."
pushd "$(mktemp -d -t "kpt-rpkg-XXX")" >/dev/null
kpt alpha rpkg pull \
    "$(kpt alpha rpkg get --name istions -o jsonpath='{.metadata.name}')" \
    --namespace default ./istions
kpt pkg tree ./istions

read -n 1 -r -p "Make local changes to the istions package."
sed -i "s/basens/istions/g;s/provisioning namespace/provisioning Istio namespace/g" istions/README.md
cat >>istions/Kptfile <<EOL
  - image: gcr.io/kpt-fn/set-labels:v0.1.5
    configMap:
      color: orange
      fruit: apple
EOL
cat istions/Kptfile

read -n 1 -r -p "Push back the local changes to remote repository."
kpt alpha rpkg push "$(kpt alpha rpkg get --name istions -o jsonpath='{.metadata.name}')" \
    ./istions -n default
popd >/dev/null

read -n 1 -r -p "Propose the package draft to be published."
kpt alpha rpkg propose \
    "$(kpt alpha rpkg get --name istions -o jsonpath='{.metadata.name}')" --namespace default
# Confirm the package revision was proposed
kpt alpha rpkg get --name istions

read -n 1 -r -p "Approve the proposed package revision for publishing"
kpt alpha rpkg approve \
    "$(kpt alpha rpkg get --name istions -o jsonpath='{.metadata.name}')" --namespace default
# Confirm the package revision was proposed
kpt alpha rpkg get --name istions
