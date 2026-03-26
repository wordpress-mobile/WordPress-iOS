#!/usr/bin/env bash
# Clone and build WebDriverAgent for iOS Simulator testing.
#
# Skips the build only when a usable build-for-testing artifact already exists.
#
# Required (one of):
#   SIMULATOR_UDID  Simulator UDID for the build destination
#   SIMULATOR_NAME  Simulator name for the build destination (e.g., iPhone 16)
#
# Optional:
#   WEBDRIVERAGENT_REPO_URL  Repo URL (default: appium/WebDriverAgent)
#   WEBDRIVERAGENT_REF       Git ref or commit to build (default: current remote HEAD / existing checkout)

set -euo pipefail

if [[ -z "${SIMULATOR_UDID:-}" && -z "${SIMULATOR_NAME:-}" ]]; then
  echo "Error: set SIMULATOR_UDID or SIMULATOR_NAME" >&2
  exit 1
fi

WDA_DIR=".build/WebDriverAgent"
WDA_PROJECT="${WDA_DIR}/WebDriverAgent.xcodeproj"
WDA_DERIVED_DATA="${WDA_DIR}/DerivedData"
WEBDRIVERAGENT_REPO_URL="${WEBDRIVERAGENT_REPO_URL:-https://github.com/appium/WebDriverAgent.git}"
WEBDRIVERAGENT_REF="${WEBDRIVERAGENT_REF:-}"

if [[ -n "${SIMULATOR_UDID:-}" ]]; then
  DESTINATION="platform=iOS Simulator,id=${SIMULATOR_UDID}"
else
  DESTINATION="platform=iOS Simulator,name=${SIMULATOR_NAME}"
fi

ensure_wda_checkout() {
  mkdir -p .build

  if [[ ! -d "${WDA_DIR}/.git" ]]; then
    git clone --depth 1 "${WEBDRIVERAGENT_REPO_URL}" "${WDA_DIR}"
  fi

  if [[ -n "${WEBDRIVERAGENT_REF}" ]]; then
    git -C "${WDA_DIR}" fetch --depth 1 origin "${WEBDRIVERAGENT_REF}"
    git -C "${WDA_DIR}" checkout --detach "${WEBDRIVERAGENT_REF}"
  fi
}

has_built_artifacts() {
  [[ -d "${WDA_DERIVED_DATA}/Build/Products" ]] && \
    find "${WDA_DERIVED_DATA}/Build/Products" -name '*.xctestrun' -print -quit | grep -q .
}

ensure_wda_checkout

if [[ -d "$WDA_PROJECT" ]] && has_built_artifacts; then
  echo "WebDriverAgent already built, skipping."
  exit 0
fi

xcodebuild build-for-testing \
  -project "$WDA_PROJECT" \
  -scheme WebDriverAgentRunner \
  -destination "$DESTINATION" \
  -derivedDataPath "$WDA_DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  | tail -1

if ! has_built_artifacts; then
  echo "Error: WebDriverAgent build completed without an .xctestrun artifact" >&2
  exit 1
fi
