#!/bin/bash -eu

echo '--- :git: Checkout release branch'

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
# Buildkite can reuse a working copy where "$BRANCH_NAME" was left at an older commit by a previous job,
# so force the local branch to the fetched commit. `reset --hard` rather than
# `git pull`, to avoid merging if the two diverged.
git reset --hard "origin/$BRANCH_NAME"
