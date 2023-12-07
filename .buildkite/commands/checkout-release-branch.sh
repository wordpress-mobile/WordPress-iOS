#!/bin/bash -eu

# RELEASE_VERSION is passed as an environment variable from fastlane to Buildkite
#
if [[ -z "${RELEASE_VERSION}" ]]; then
    echo "RELEASE_VERSION is not set."
    exit 1
fi

# Buildkite, by default, checks out a specific commit. For many release actions, we need to be
# on a release branch instead.
BRANCH_NAME="release/${RELEASE_VERSION}"
git fetch origin "$BRANCH_NAME"
git checkout "$BRANCH_NAME"
