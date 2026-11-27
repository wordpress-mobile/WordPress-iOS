#!/bin/bash -euo pipefail

SCHEME="${1:?Usage $0 SCHEME}"
DEVICE="iPhone 18 Pro"

$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh

xcodebuild \
  -scheme "${SCHEME}" \
  -destination "platform=iOS Simulator,name=${DEVICE}" \
  test \
  | xcbeautify
