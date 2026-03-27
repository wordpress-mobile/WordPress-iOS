#!/usr/bin/env bash
# Capture a screenshot for the current AI-driven test case and print the
# relative path that should be stored in the result metadata.
#
# A hard cap of 3 screenshots per test is enforced to prevent wasting
# turns on unnecessary screenshots during normal flow.
#
# Usage: take-ai-test-screenshot.sh <label>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=Scripts/ci/ai-test-progress.sh
source "$SCRIPT_DIR/ai-test-progress.sh"

LABEL="${1:?Usage: take-ai-test-screenshot.sh <label>}"

: "${SIMULATOR_UDID:?SIMULATOR_UDID is required}"
: "${AI_TEST_RESULTS_DIR:?AI_TEST_RESULTS_DIR is required}"
: "${AI_TEST_SCREENSHOTS_DIR:?AI_TEST_SCREENSHOTS_DIR is required}"
: "${AI_TEST_SLUG:?AI_TEST_SLUG is required}"

MAX_SCREENSHOTS=3
existing_count="$(find "$AI_TEST_SCREENSHOTS_DIR" -maxdepth 1 -name "${AI_TEST_SLUG}-*" -type f 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$existing_count" -ge "$MAX_SCREENSHOTS" ]]; then
  log_ai_test_progress "Screenshot skipped (limit of ${MAX_SCREENSHOTS} reached)"
  echo "Screenshot limit reached (${MAX_SCREENSHOTS} per test). Save turns for actions instead."
  exit 0
fi

safe_label="$(echo "$LABEL" | tr -cs '[:alnum:]_-' '_')"
mkdir -p "$AI_TEST_SCREENSHOTS_DIR"
absolute_path="$(mktemp "${AI_TEST_SCREENSHOTS_DIR}/${AI_TEST_SLUG}-${safe_label}-XXXX.png")"
xcrun simctl io "$SIMULATOR_UDID" screenshot "$absolute_path" >/dev/null

relative_path="${absolute_path#${AI_TEST_RESULTS_DIR}/}"
log_ai_test_progress "Screenshot: ${relative_path}"
echo "$relative_path"
