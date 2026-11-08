#!/bin/bash -eu

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type validation; then
  exit 0
fi

echo "--- :swift: Restoring Swift Packages cache"
restore_swiftpm_cache --package-resolved Package.resolved --artifacts .build

echo "--- :swift: Running cross-platform Swift package tests"
set +e
swift test
SWIFT_TEST_EXIT_STATUS=$?
set -e

echo "--- :swift: Saving Swift Packages cache"
save_swiftpm_cache --package-resolved Package.resolved --artifacts .build

# Runs here rather than in its own job, to save starting another Mac VM for a few seconds of work.
"$(dirname "${BASH_SOURCE[0]}")/verify-strings-catalog.sh"

exit $SWIFT_TEST_EXIT_STATUS
