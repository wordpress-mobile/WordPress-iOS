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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=Scripts/ci/ai-test-progress.sh
source "$SCRIPT_DIR/ai-test-progress.sh"

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

log_request() {
  case "$URL_PATH" in
    /source\?format=description)
      log_ai_test_progress 'Fetched accessibility tree'
      ;;
    /source\?format=json)
      log_ai_test_progress 'Fetched accessibility tree JSON'
      ;;
    /session)
      log_ai_test_progress 'Creating WDA session'
      ;;
    /session/*/elements)
      local using
      local value
      using="$(printf '%s' "$BODY" | ruby -rjson -e 'body = STDIN.read; data = JSON.parse(body); print data["using"].to_s' 2>/dev/null || true)"
      value="$(printf '%s' "$BODY" | ruby -rjson -e 'body = STDIN.read; data = JSON.parse(body); print data["value"].to_s' 2>/dev/null || true)"
      if [[ -n "$using" || -n "$value" ]]; then
        log_ai_test_progress "Find element using ${using:-unknown}: ${value:-<empty>}"
      else
        log_ai_test_progress 'Find element'
      fi
      ;;
    /session/*/element/*/click)
      log_ai_test_progress 'Clicked element'
      ;;
    /session/*/wda/keys)
      local key_count
      key_count="$(printf '%s' "$BODY" | ruby -rjson -e 'body = STDIN.read; data = JSON.parse(body); values = data["value"]; print(values.is_a?(Array) ? values.length : 0)' 2>/dev/null || true)"
      if [[ -n "$key_count" && "$key_count" != "0" ]]; then
        log_ai_test_progress "Typed ${key_count} key(s)"
      else
        log_ai_test_progress 'Typed keys'
      fi
      ;;
    /session/*/wda/pressButton)
      local button_name
      button_name="$(printf '%s' "$BODY" | ruby -rjson -e 'body = STDIN.read; data = JSON.parse(body); print data["name"].to_s' 2>/dev/null || true)"
      if [[ -n "$button_name" ]]; then
        log_ai_test_progress "Pressed ${button_name} button"
      else
        log_ai_test_progress 'Pressed hardware button'
      fi
      ;;
    /session/*/actions)
      log_ai_test_progress 'Performed touch action'
      ;;
    /status)
      log_ai_test_progress 'Checked WDA status'
      ;;
  esac
}

log_request

if [[ -n "$BODY" ]]; then
  exec curl -sS --max-time 30 -X "$METHOD" \
    -H 'Content-Type: application/json' \
    -d "$BODY" \
    "http://localhost:${PORT}${URL_PATH}"
else
  exec curl -sS --max-time 30 -X "$METHOD" \
    "http://localhost:${PORT}${URL_PATH}"
fi
