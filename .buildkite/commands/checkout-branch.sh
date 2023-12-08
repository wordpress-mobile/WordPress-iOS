#!/bin/bash -eu

BRANCH_NAME=$1

if [[ -z "${BRANCH_NAME}" ]]; then
    echo "Usage $0 <branch name>"
    exit 1
fi

# Buildkite, by default, checks out a specific commit.
# For many release actions, we need to be on a specific branch instead.
git fetch origin "$BRANCH_NAME"
git checkout "$BRANCH_NAME"
