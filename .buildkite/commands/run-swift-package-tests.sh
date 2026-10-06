#!/bin/bash -eu

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type validation; then
  exit 0
fi

# The HTTPFixtures module and its tests are compiled out unless this condition is set.
echo "--- :swift: Running cross-platform Swift package tests"
swift test -Xswiftc -DUI_TEST_HTTP_FIXTURES
