#!/bin/bash -eu

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type validation; then
  exit 0
fi

echo "--- :swift: Running cross-platform Swift package tests"
swift test
