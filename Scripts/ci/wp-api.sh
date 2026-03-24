#!/usr/bin/env bash
# Constrained WordPress REST API client.
# Handles authentication internally — Claude Code never sees credentials.
#
# Usage: wp-api.sh <METHOD> <API_PATH> [JSON_BODY]
#
# Examples:
#   wp-api.sh GET  'wp/v2/posts?search=My+Post'
#   wp-api.sh POST  wp/v2/posts '{"title":"Test","status":"publish"}'
#   wp-api.sh DELETE 'wp/v2/posts/123?force=true'
#
# Environment (required):
#   SITE_URL        WordPress site URL (e.g., https://example.com)
#   WP_USERNAME     WordPress username
#   WP_APP_PASSWORD WordPress application password
set -euo pipefail

METHOD="${1:?Usage: wp-api.sh METHOD API_PATH [BODY]}"
API_PATH="${2:?Usage: wp-api.sh METHOD API_PATH [BODY]}"
BODY="${3:-}"

: "${SITE_URL:?SITE_URL is required}"
: "${WP_USERNAME:?WP_USERNAME is required}"
: "${WP_APP_PASSWORD:?WP_APP_PASSWORD is required}"

case "$METHOD" in
  GET|POST|PUT|DELETE) ;;
  *) echo "Error: method must be GET, POST, PUT, or DELETE, got '$METHOD'" >&2; exit 1 ;;
esac

# Reject path traversal
if [[ "$API_PATH" == *..* ]]; then
  echo "Error: path traversal ('..') is not allowed" >&2
  exit 1
fi

# Strip leading slash if present
API_PATH="${API_PATH#/}"

if [ -n "$BODY" ]; then
  exec curl -s -X "$METHOD" \
    -u "${WP_USERNAME}:${WP_APP_PASSWORD}" \
    -H 'Content-Type: application/json' \
    -d "$BODY" \
    "${SITE_URL}/wp-json/${API_PATH}"
else
  exec curl -s -X "$METHOD" \
    -u "${WP_USERNAME}:${WP_APP_PASSWORD}" \
    "${SITE_URL}/wp-json/${API_PATH}"
fi
