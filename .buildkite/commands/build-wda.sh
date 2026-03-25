#!/usr/bin/env bash
# Clone and build WebDriverAgent for iOS Simulator testing.
#
# Skips if WDA is already built at .build/WebDriverAgent/.
#
# Required:
#   SIMULATOR_NAME  Simulator name for the build destination (e.g., iPhone 16)

set -euo pipefail

SIMULATOR_NAME="${SIMULATOR_NAME:?Set SIMULATOR_NAME}"
WDA_PROJECT=".build/WebDriverAgent/WebDriverAgent.xcodeproj"

if [[ -d "$WDA_PROJECT" ]]; then
  echo "WebDriverAgent already built, skipping."
  return 0 2>/dev/null || exit 0
fi

mkdir -p .build
git clone --depth 1 https://github.com/appium/WebDriverAgent.git .build/WebDriverAgent

xcodebuild build-for-testing \
  -project "$WDA_PROJECT" \
  -scheme WebDriverAgentRunner \
  -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
  CODE_SIGNING_ALLOWED=NO \
  | tail -1
