#!/bin/bash -eu

# Checks out the `release/*` branch for a given release version.
#
# Usage: checkout-release-branch.sh [<RELEASE_VERSION>]
#
# The release version is taken from the first of these that is set and non-empty:
#  1. the first argument
#  2. the `RELEASE_VERSION` environment variable
#  3. the `release/*` branch the build is running on, via `BUILDKITE_BRANCH`
#
# Buildkite, by default, checks out a specific commit, ending up in a detached HEAD state.
# But some release steps need to be on the `release/*` branch instead, namely:
#  - when a `release-pipelines/*.yml` needs to `git push` to the `release/*` branch (for version bumps)
#  - when a job `pipeline upload`'d by such a pipeline builds from that branch, so that the build
#    includes the commit that the version bump just added.

echo "--- :git: Checkout Release Branch"

RELEASE_VERSION="${1:-${RELEASE_VERSION:-}}"

if [[ -z "$RELEASE_VERSION" && "${BUILDKITE_BRANCH:-}" =~ ^release/ ]]; then
  RELEASE_VERSION="${BUILDKITE_BRANCH#release/}"
fi

if [[ -z "$RELEASE_VERSION" ]]; then
  echo "Error: no release version. Pass it as \$1, set RELEASE_VERSION, or run on a release/* branch." >&2
  exit 1
fi

BRANCH_NAME="release/${RELEASE_VERSION}"
git fetch origin "$BRANCH_NAME"
git checkout "$BRANCH_NAME"
# Buildkite can reuse a working copy where "$BRANCH_NAME" was left at a different commit by a previous job,
# so force the local branch to the fetched commit. `reset --hard` rather than
# `git pull`, to avoid merging if the two diverged; `FETCH_HEAD` rather than
# `origin/$BRANCH_NAME`, which `git fetch <branch>` only updates opportunistically.
git reset --hard FETCH_HEAD
