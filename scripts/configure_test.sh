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
set -o nounset
[[ ${DEBUG:-false} != "true" ]] || set -o xtrace

# shellcheck source=./scripts/_assertions.sh
source _assertions.sh
# shellcheck source=scripts/_common.sh
source _common.sh

info "Assert KinD clusters creation"
assert_non_empty "$(sudo docker ps --filter label=io.x-k8s.kind.role=control-plane --quiet)" "There are no KinD clusters running"

info "Assert gitea users creation"
assert_contains "$(exec_gitea admin user list --admin)" "$gitea_admin_account"

info "Assert gitea organization creation"
assert_contains "$(curl_gitea_api orgs)" "$gitea_org"

info "Assert gitea repos creation"
gitea_org_repos="$(curl_gitea_api "orgs/$gitea_org/repos")"
for repo in "${gitea_repos[@]}"; do
    assert_contains "$gitea_org_repos" "$repo"
done
