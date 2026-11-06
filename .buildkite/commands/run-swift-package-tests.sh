#!/bin/bash -eu

SWIFT_TEST_EXIT_STATUS=0
if ! "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type swift-packages; then
  echo "--- :swift: Restoring Swift Packages cache"
  restore_swiftpm_cache --package-resolved Package.resolved --artifacts .build

  echo "--- :swift: Running cross-platform Swift package tests"
  set +e
  swift test
  SWIFT_TEST_EXIT_STATUS=$?
  set -e

  echo "--- :swift: Saving Swift Packages cache"
  save_swiftpm_cache --package-resolved Package.resolved --artifacts .build
fi

# Runs here rather than in its own job, to save starting another Mac VM for a few seconds of work.
# App-only changes still need this check even when the package tests skip.
"$(dirname "${BASH_SOURCE[0]}")/verify-strings-catalog.sh"

exit $SWIFT_TEST_EXIT_STATUS
