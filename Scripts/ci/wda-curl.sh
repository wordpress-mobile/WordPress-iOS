#!/usr/bin/env bash
# Constrained HTTP proxy to WebDriverAgent on localhost.
# All WDA interactions from Claude Code go through this script.
#
# Usage: wda-curl.sh <METHOD> <PATH> [JSON_BODY]
#
# Examples:
#   wda-curl.sh GET  /status
#   wda-curl.sh GET  '/source?format=description'
#   wda-curl.sh POST /session '{"capabilities":{"alwaysMatch":{}}}'
#   wda-curl.sh POST /session/ID/actions '{"actions":[...]}'
#
# Environment:
#   WDA_PORT  WDA port (default: 8100)
set -euo pipefail

METHOD="${1:?Usage: wda-curl.sh METHOD PATH [BODY]}"
URL_PATH="${2:?Usage: wda-curl.sh METHOD PATH [BODY]}"
BODY="${3:-}"
PORT="${WDA_PORT:-8100}"

case "$METHOD" in
  GET|POST) ;;
  *) echo "Error: method must be GET or POST, got '$METHOD'" >&2; exit 1 ;;
esac

# Ensure path starts with /
if [[ "$URL_PATH" != /* ]]; then
  URL_PATH="/${URL_PATH}"
fi

case "$URL_PATH" in
  /status|/session|/source\?format=description|/source\?format=json|/session/*/actions|/session/*/elements|/session/*/element/*/click|/session/*/wda/keys|/session/*/wda/pressButton) ;;
  *)
    echo "Error: WDA path '$URL_PATH' is not allowed" >&2
    exit 1
    ;;
esac

if [[ -n "$BODY" ]]; then
  exec curl -sS --max-time 30 -X "$METHOD" \
    -H 'Content-Type: application/json' \
    -d "$BODY" \
    "http://localhost:${PORT}${URL_PATH}"
else
  exec curl -sS --max-time 30 -X "$METHOD" \
    "http://localhost:${PORT}${URL_PATH}"
fi
