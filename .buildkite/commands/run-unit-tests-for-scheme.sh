#!/bin/bash -euo pipefail

SCHEME="${1:?Usage $0 SCHEME}"
DEVICE="iPhone 17"
OS_VERSION="26.0"

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type validation; then
  exit 0
fi

$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh

xcodebuild \
  -scheme "${SCHEME}" \
  -destination "platform=iOS Simulator,OS=${OS_VERSION},name=${DEVICE}" \
  test \
  | xcbeautify
