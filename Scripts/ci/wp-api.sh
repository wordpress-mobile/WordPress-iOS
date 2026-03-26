#!/usr/bin/env bash
# Constrained WordPress REST API client.
# Handles authentication internally and records whether setup / verification /
# cleanup calls succeeded for the current test.
#
# Usage: wp-api.sh <PURPOSE> <METHOD> <API_PATH> [JSON_BODY]
#
# Examples:
#   wp-api.sh setup GET 'wp/v2/posts?search=My+Post'
#   wp-api.sh verification POST wp/v2/posts '{"title":"Test","status":"publish"}'
#   wp-api.sh cleanup DELETE 'wp/v2/posts/123?force=true'
#
# Environment (required):
#   SITE_URL        WordPress site URL (e.g., https://example.com)
#   WP_USERNAME     WordPress username
#   WP_APP_PASSWORD WordPress application password
#   AI_TEST_USAGE_FILE  Path to the per-test usage log
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=Scripts/ci/ai-test-progress.sh
source "$SCRIPT_DIR/ai-test-progress.sh"

PURPOSE="${1:?Usage: wp-api.sh PURPOSE METHOD API_PATH [BODY]}"
METHOD="${2:?Usage: wp-api.sh PURPOSE METHOD API_PATH [BODY]}"
API_PATH="${3:?Usage: wp-api.sh PURPOSE METHOD API_PATH [BODY]}"
BODY="${4:-}"

: "${SITE_URL:?SITE_URL is required}"
: "${WP_USERNAME:?WP_USERNAME is required}"
: "${WP_APP_PASSWORD:?WP_APP_PASSWORD is required}"
: "${AI_TEST_USAGE_FILE:?AI_TEST_USAGE_FILE is required}"

case "$PURPOSE" in
  setup|verification|cleanup) ;;
  *) echo "Error: purpose must be setup, verification, or cleanup, got '$PURPOSE'" >&2; exit 1 ;;
esac

case "$METHOD" in
  GET|POST|PUT|DELETE) ;;
  *) echo "Error: method must be GET, POST, PUT, or DELETE, got '$METHOD'" >&2; exit 1 ;;
esac

# Reject path traversal
if [[ "$API_PATH" == *..* ]]; then
  echo "Error: path traversal ('..') is not allowed" >&2
  exit 1
fi

if [[ "$API_PATH" == http://* || "$API_PATH" == https://* ]]; then
  echo "Error: absolute URLs are not allowed" >&2
  exit 1
fi

# Strip leading slash if present
API_PATH="${API_PATH#/}"
API_PATH="${API_PATH#wp-json/}"

tmp_body="$(mktemp)"
trap 'rm -f "$tmp_body"' EXIT

log_usage() {
  printf '%s\t%s\t%s\n' "$PURPOSE" "$1" "$2" >> "$AI_TEST_USAGE_FILE"
}

if [[ -n "$BODY" ]]; then
  status_code="$(curl -sS --max-time 30 -o "$tmp_body" -w '%{http_code}' -X "$METHOD" \
    -u "${WP_USERNAME}:${WP_APP_PASSWORD}" \
    -H 'Content-Type: application/json' \
    -d "$BODY" \
    "${SITE_URL}/wp-json/${API_PATH}")"
else
  status_code="$(curl -sS --max-time 30 -o "$tmp_body" -w '%{http_code}' -X "$METHOD" \
    -u "${WP_USERNAME}:${WP_APP_PASSWORD}" \
    "${SITE_URL}/wp-json/${API_PATH}")"
fi

if [[ "$status_code" =~ ^2[0-9][0-9]$ ]]; then
  log_usage "$status_code" 1
else
  log_usage "$status_code" 0
fi

log_ai_test_progress "REST ${PURPOSE} ${METHOD} /wp-json/${API_PATH} -> ${status_code}"

printf 'HTTP %s\n' "$status_code"
cat "$tmp_body"
