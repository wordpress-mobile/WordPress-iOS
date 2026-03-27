#!/usr/bin/env bash
# Find an element by accessibility ID or label and tap it in one call.
# Combines the find-element + click WDA calls that otherwise cost two turns.
#
# Usage: tap-element.sh <IDENTIFIER_OR_LABEL>
#
# Tries accessibility ID first, then label. Prints the element JSON on
# success or an error message on failure.
#
# Environment:
#   WDA_PORT        WDA port (default: 8100)
#   WDA_SESSION_ID  Active WDA session ID
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=Scripts/ci/ai-test-progress.sh
source "$SCRIPT_DIR/ai-test-progress.sh"

SELECTOR="${1:?Usage: tap-element.sh IDENTIFIER_OR_LABEL}"
PORT="${WDA_PORT:-8100}"
SESSION="${WDA_SESSION_ID:?WDA_SESSION_ID is required}"
BASE="http://localhost:${PORT}/session/${SESSION}"

find_elements() {
  local using="$1"
  local value="$2"
  curl -sS --max-time 10 -X POST \
    -H 'Content-Type: application/json' \
    -d "{\"using\":\"${using}\",\"value\":\"${value}\"}" \
    "${BASE}/elements"
}

click_element() {
  local element_id="$1"
  curl -sS --max-time 10 -X POST "${BASE}/element/${element_id}/click"
}

extract_element_id() {
  # Extract the ELEMENT id from the first match in the WDA response.
  # WDA returns value[0].ELEMENT (the key is literally "ELEMENT").
  ruby -rjson -e '
    data = JSON.parse(STDIN.read)
    values = data["value"]
    if values.is_a?(Array) && !values.empty?
      eid = values[0]["ELEMENT"] || values[0].values.first
      print eid
    end
  ' 2>/dev/null
}

# Try accessibility ID first
response="$(find_elements "accessibility id" "$SELECTOR")"
element_id="$(printf '%s' "$response" | extract_element_id)"

# Fall back to label
if [[ -z "$element_id" ]]; then
  response="$(find_elements "link text" "$SELECTOR")"
  element_id="$(printf '%s' "$response" | extract_element_id)"
fi

if [[ -z "$element_id" ]]; then
  log_ai_test_progress "Element not found: ${SELECTOR}"
  echo "Error: element not found for '${SELECTOR}'" >&2
  echo "$response"
  exit 1
fi

log_ai_test_progress "Tapped element '${SELECTOR}'"
click_element "$element_id"
