#!/usr/bin/env bash
# Record the final pass/fail status for the current AI-driven test case.
#
# Usage: record-ai-test-result.sh <pass|fail> <reason> [screenshot-relative-path]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=Scripts/ci/ai-test-progress.sh
source "$SCRIPT_DIR/ai-test-progress.sh"

STATUS="${1:?Usage: record-ai-test-result.sh <pass|fail> <reason> [screenshot-relative-path]}"
REASON="${2:?Usage: record-ai-test-result.sh <pass|fail> <reason> [screenshot-relative-path]}"
SCREENSHOT_REL="${3:-}"

: "${AI_TEST_RESULT_FILE:?AI_TEST_RESULT_FILE is required}"
: "${AI_TEST_RESULT_EVENTS_FILE:?AI_TEST_RESULT_EVENTS_FILE is required}"
: "${AI_TEST_TITLE:?AI_TEST_TITLE is required}"
: "${AI_TEST_FILE:?AI_TEST_FILE is required}"

mkdir -p "$(dirname "$AI_TEST_RESULT_EVENTS_FILE")"
printf '%s\t%s\n' "$(date +%s)" "$STATUS" >> "$AI_TEST_RESULT_EVENTS_FILE"

ruby Scripts/ci/write-ai-test-result.rb \
  "$AI_TEST_RESULT_FILE" \
  "$AI_TEST_TITLE" \
  "$AI_TEST_FILE" \
  "$STATUS" \
  "$REASON" \
  "$SCREENSHOT_REL"

log_ai_test_progress "Test result: $(printf '%s' "$STATUS" | tr '[:lower:]' '[:upper:]') — ${REASON}"
echo "Recorded ${STATUS} result for ${AI_TEST_TITLE}"
