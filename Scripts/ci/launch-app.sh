#!/usr/bin/env bash
# Launch the app on the simulator with test credentials.
# Takes no arguments — all values come from environment variables.
#
# Usage: launch-app.sh
#
# Environment (required):
#   SIMULATOR_UDID   Simulator UDID
#   APP_BUNDLE_ID    App bundle ID (org.wordpress or com.automattic.jetpack)
#   SITE_URL         WordPress site URL
#   WP_USERNAME      WordPress username
#   WP_APP_PASSWORD  WordPress application password
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=Scripts/ci/ai-test-progress.sh
source "$SCRIPT_DIR/ai-test-progress.sh"

: "${SIMULATOR_UDID:?SIMULATOR_UDID is required}"
: "${APP_BUNDLE_ID:?APP_BUNDLE_ID is required}"
: "${SITE_URL:?SITE_URL is required}"
: "${WP_USERNAME:?WP_USERNAME is required}"
: "${WP_APP_PASSWORD:?WP_APP_PASSWORD is required}"

launch_output="$(xcrun simctl launch --terminate-running-process \
  "$SIMULATOR_UDID" "$APP_BUNDLE_ID" \
  -ui-testing YES \
  -ui-test-reset-everything YES \
  -ui-test-disable-prompts YES \
  -ui-test-disable-animations YES \
  -ui-test-disable-migration YES \
  -ui-test-site-url "$SITE_URL" \
  -ui-test-site-user "$WP_USERNAME" \
  -ui-test-site-pass "$WP_APP_PASSWORD")"

log_ai_test_progress "Launched ${APP_BUNDLE_ID}"
printf '%s\n' "$launch_output"
