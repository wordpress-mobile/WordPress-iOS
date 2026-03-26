#!/usr/bin/env bash
# Capture a screenshot for the current AI-driven test case and print the
# relative path that should be stored in the result metadata.
#
# Usage: take-ai-test-screenshot.sh <label>
set -euo pipefail

LABEL="${1:?Usage: take-ai-test-screenshot.sh <label>}"

: "${SIMULATOR_UDID:?SIMULATOR_UDID is required}"
: "${AI_TEST_RESULTS_DIR:?AI_TEST_RESULTS_DIR is required}"
: "${AI_TEST_SCREENSHOTS_DIR:?AI_TEST_SCREENSHOTS_DIR is required}"
: "${AI_TEST_SLUG:?AI_TEST_SLUG is required}"

safe_label="$(echo "$LABEL" | tr -cs '[:alnum:]_-' '_')"
mkdir -p "$AI_TEST_SCREENSHOTS_DIR"
absolute_path="$(mktemp "${AI_TEST_SCREENSHOTS_DIR}/${AI_TEST_SLUG}-${safe_label}-XXXX.png")"
xcrun simctl io "$SIMULATOR_UDID" screenshot "$absolute_path" >/dev/null

relative_path="${absolute_path#${AI_TEST_RESULTS_DIR}/}"
echo "$relative_path"
