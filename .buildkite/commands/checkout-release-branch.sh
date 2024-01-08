#!/bin/bash -eu

RELEASE_NUMBER=$1

if [[ -z "${RELEASE_NUMBER}" ]]; then
    echo "Usage $0 <release number, e.g. 1.2.3>"
    exit 1
fi

# Buildkite, by default, checks out a specific commit.
# For many release actions, we need to be on a release branch instead.
BRANCH_NAME="release/${RELEASE_NUMBER}"
git fetch origin "$BRANCH_NAME"
git checkout "$BRANCH_NAME"
