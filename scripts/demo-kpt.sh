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

pushd "$(mktemp -d -t "kpt-pkg-XXX")" >/dev/null
trap popd EXIT
# Fetch wordpress kpt package into /tmp/wordpress folder
kpt pkg get https://github.com/GoogleContainerTools/kpt.git/package-examples/wordpress@v0.9

# Examine kpt metadata file
# Independent package
cat wordpress/Kptfile
# Dependent package
cat wordpress/mysql/Kptfile

# Explore wordpress package
kpt pkg tree wordpress

# Search for tier labels
kpt fn eval wordpress -i search-replace:v0.1 -- 'by-path=spec.selector.tier'

# Initialize the local repo
git init
git add .
git commit -m "Pristine wordpress package"

# Setting a label on all resources
kpt fn eval wordpress -i set-labels:v0.1 -- env=dev
git --no-pager diff

# Enforces package preconditions, executes functions and guarantees package postconditions
kpt fn render wordpress
git --no-pager diff

# Commit local changes
git add .
git commit -m "My changes"

# Update package
kpt pkg update wordpress@v0.10
git --no-pager diff

# Comimit local changes
git add .
git commit -m "Updated wordpress to v0.10"
