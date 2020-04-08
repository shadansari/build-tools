#!/bin/bash
# Copyright 2020-present Open Networking Foundation.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Poor-man's tool to bump the onosproject dependencies for a project:
#   1) "go get -u" on the dependencies with the new tag
#   2) create a branch
#   3) push to git

# The tool requires the user to have the authorization to:
#   1) push tag to the upstream repo

# Also, the following conditions must be met:
#   1) repo must have upstream (or origin) remote push enabled via ssh
#   2) non-empty version number is specified

version="${1}"
shift 1

# Validate args...
[ -z "$version" -o $# -lt 1 ] && echo "usage: $0 <version> <dependencies>..." >&2 && exit 1

# Validate upstream (or origin) push URL is via SSH...
git remote -v | grep upstream | grep -q push && upstream="upstream" || upstream="origin"
! git remote -v | grep $upstream | grep push | cut -f2 | cut -d\  -f1 | grep -q 'git@github.com:' && \
      echo "Upstream remote not setup with SSH push URL" >&2 && exit 1

# Validate we are on master
! git status -b | grep "On branch" | cut -d\  -f3 | grep -q master && \
      echo "Not on master branch" >&2 && exit 1

! git status -b | grep -q "nothing to commit, working tree clean" && \
      echo "There are modified files" >&2 && exit 1

# 1) Run "go get -u"
for dependency in "$@"; do
  GO111MODULE=on go get -u github.com/onosproject/$dependency@$version
done
GO111MODULE=on go build -v ./...

# 2) Create a branch and push it
git checkout -b onosdeps$version && \
git add go.mod go.sum && \
git commit -m"Bump to $version of onosproject dependencies" && \
git push upstream