#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../../.buildkite/commands/run-ai-e2e-tests.sh
source "$REPO_ROOT/.buildkite/commands/run-ai-e2e-tests.sh"

TEST_TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ai-e2e-preflight-tests.XXXXXX" 2>/dev/null || mktemp -d -t ai-e2e-preflight-tests)"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

assert_equal() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL: ${message}" >&2
    echo "Expected: ${expected}" >&2
    echo "Actual: ${actual}" >&2
    exit 1
  fi
}

disabled_response="$TEST_TMP_DIR/disabled.xml"
enabled_response="$TEST_TMP_DIR/enabled.xml"
rate_limited_response="$TEST_TMP_DIR/rate-limited.html"
unexpected_response="$TEST_TMP_DIR/unexpected.xml"
valid_run_log="$TEST_TMP_DIR/valid-run.log"
invalid_run_log="$TEST_TMP_DIR/invalid-run.log"
compatible_executor="$TEST_TMP_DIR/compatible-tool-executor.rb"
incompatible_executor="$TEST_TMP_DIR/incompatible-tool-executor.rb"

printf '%s' \
  '<?xml version="1.0"?><methodResponse><fault><value><struct><member><name>faultCode</name><value><int>405</int></value></member><member><name>faultString</name><value><string>Los servicios XML-RPC están desactivados en este sitio.</string></value></member></struct></value></fault></methodResponse>' \
  > "$disabled_response"
printf '%s' \
  '<?xml version="1.0"?><methodResponse><fault><value><struct><member><name>faultCode</name><value><int>403</int></value></member><member><name>faultString</name><value><string>Nombre de usuario o contraseña incorrectos.</string></value></member></struct></value></fault></methodResponse>' \
  > "$enabled_response"
printf '%s' '<html><body>Too Many Requests</body></html>' > "$rate_limited_response"
printf '%s' '<error>Service unavailable</error>' > "$unexpected_response"
printf '%s\n' \
  '[12:00:00] REST setup GET /wp-json/wp/v2/categories -> 200' \
  '[12:00:01] REST verification GET /wp-json/wp/v2/posts -> 200' \
  '[12:00:02] REST cleanup DELETE /wp-json/wp/v2/posts/123 -> 200' \
  > "$valid_run_log"
printf '%s\n' \
  '[12:00:00] REST setup POST /wp-json/wp/v2/posts -> 201' \
  '[12:00:01] REST verification PUT /wp-json/wp/v2/pages/456 -> 200' \
  '[12:00:02] REST setup PATCH /wp-json/wp/v2/categories/12 -> 200' \
  '[12:00:03] REST cleanup POST /wp-json/wp/v2/tags -> 201' \
  '[12:00:04] REST verification DELETE /wp-json/wp/v2/posts/789 -> 200' \
  > "$invalid_run_log"
printf '%s\n' \
  '@logger.info "  REST #{purpose} #{method} #{path} -> #{response.code}"' \
  > "$compatible_executor"
printf '%s\n' \
  '@logger.info JSON.generate(rest_event)' \
  > "$incompatible_executor"

assert_equal "405" "$(xmlrpc_fault_code "$disabled_response")" "extracts an XML-RPC fault code"
assert_equal "unavailable" "$(detect_xmlrpc_availability "$disabled_response" "405" "text/xml; charset=UTF-8")" "detects a localized disabled XML-RPC response"
assert_equal "available" "$(detect_xmlrpc_availability "$enabled_response" "200" "text/xml; charset=UTF-8")" "detects an enabled XML-RPC response"
assert_equal "unknown" "$(detect_xmlrpc_availability "$rate_limited_response" "429" "text/html")" "rejects a rate-limited HTML response"
assert_equal "unknown" "$(detect_xmlrpc_availability "$unexpected_response" "503" "text/xml")" "rejects an ambiguous XML response"
assert_equal "any" "$(BUILDKITE= default_expected_xmlrpc_availability)" "uses a permissive local XML-RPC default"
assert_equal "unavailable" "$(BUILDKITE=1 default_expected_xmlrpc_availability)" "uses the test-site contract in Buildkite"

validate_expected_xmlrpc_availability "unavailable"
validate_expected_xmlrpc_availability "available"
validate_expected_xmlrpc_availability "any"
validate_expected_xmlrpc_unavailable_http_status ""
validate_expected_xmlrpc_unavailable_http_status "429"

if validate_expected_xmlrpc_availability "sometimes" >/dev/null 2>&1; then
  echo "FAIL: accepts an invalid expected XML-RPC availability" >&2
  exit 1
fi
if validate_expected_xmlrpc_unavailable_http_status "rate-limited" >/dev/null 2>&1; then
  echo "FAIL: accepts an invalid expected XML-RPC unavailable HTTP status" >&2
  exit 1
fi
if validate_expected_xmlrpc_unavailable_http_status "503" >/dev/null 2>&1; then
  echo "FAIL: accepts an unexpected XML-RPC unavailable HTTP status" >&2
  exit 1
fi

validate_simulator_llm_pilot_rest_log_contract "$compatible_executor" >/dev/null
if validate_simulator_llm_pilot_rest_log_contract "$incompatible_executor" >/dev/null 2>&1; then
  echo "FAIL: accepts an incompatible simulator-llm-pilot REST logger" >&2
  exit 1
fi

curl() {
  local output_file

  printf '%s\n' "$@" > "$MOCK_CURL_ARGS_FILE"
  while [[ "$#" -gt 0 ]]; do
    if [[ "$1" == "--output" ]]; then
      output_file="$2"
      shift 2
    else
      shift
    fi
  done

  cp "$MOCK_XMLRPC_BODY_FILE" "$output_file"
  printf '%s' "$MOCK_XMLRPC_CURL_OUTPUT"
}

PREFLIGHT_TMP_DIR="$TEST_TMP_DIR"
SIMULATOR_LLM_PILOT_USERNAME='user&<name>'
SIMULATOR_LLM_PILOT_APP_PASSWORD='pass&<word>'
MOCK_XMLRPC_BODY_FILE="$disabled_response"
MOCK_XMLRPC_CURL_OUTPUT='405 https://example.com/xmlrpc.php 0 text/xml; charset=UTF-8'
MOCK_CURL_ARGS_FILE="$TEST_TMP_DIR/xmlrpc-curl-args.log"
preflight_xmlrpc_availability "https://example.com" "unavailable" >/dev/null

if grep -qF "$SIMULATOR_LLM_PILOT_USERNAME" "$MOCK_CURL_ARGS_FILE"; then
  echo "FAIL: XML-RPC probe includes the test username" >&2
  exit 1
fi
if grep -qF "$SIMULATOR_LLM_PILOT_APP_PASSWORD" "$MOCK_CURL_ARGS_FILE"; then
  echo "FAIL: XML-RPC probe includes the application password" >&2
  exit 1
fi
if grep -qxF -- '--location' "$MOCK_CURL_ARGS_FILE"; then
  echo "FAIL: XML-RPC probe follows redirects" >&2
  exit 1
fi
if ! grep -qF 'ai-e2e-preflight' "$MOCK_CURL_ARGS_FILE"; then
  echo "FAIL: XML-RPC probe does not use dummy credentials" >&2
  exit 1
fi

MOCK_XMLRPC_BODY_FILE="$rate_limited_response"
MOCK_XMLRPC_CURL_OUTPUT='429 https://example.com/xmlrpc.php 0 text/html'
if preflight_xmlrpc_availability "https://example.com" "unavailable" >/dev/null 2>&1; then
  echo "FAIL: XML-RPC preflight accepts a transient non-XML response" >&2
  exit 1
fi
assert_equal \
  "OK: XML-RPC is unavailable via expected HTTP 429" \
  "$(preflight_xmlrpc_availability "https://example.com" "unavailable" "429")" \
  "accepts an explicitly configured XML-RPC transport block"

MOCK_XMLRPC_CURL_OUTPUT='307 https://example.com/xmlrpc.php 0 text/html'
if preflight_xmlrpc_availability "https://example.com" "unavailable" >/dev/null 2>&1; then
  echo "FAIL: XML-RPC preflight accepts a redirect" >&2
  exit 1
fi
unset -f curl

rest_event='[12:00:00] REST setup POST /wp-json/wp/v2/posts -> 201'
colored_rest_event="${rest_event}"$'\033[0m'
captured_output="$(
  printf '%s\n' \
    $'\033[31m'"${colored_rest_event}" \
    'ANTHROPIC_API_KEY=must-not-be-persisted' |
    capture_rest_contract_events "$TEST_TMP_DIR/captured-rest-events.log"
)"
assert_equal \
  $'\033[31m'"${colored_rest_event}"$'\n''ANTHROPIC_API_KEY=must-not-be-persisted' \
  "$captured_output" \
  "passes the full runner output through to the build log"
assert_equal \
  "$rest_event" \
  "$(cat "$TEST_TMP_DIR/captured-rest-events.log")" \
  "persists only sanitized REST contract events"

if find_forbidden_rest_mutations "$valid_run_log" >/dev/null; then
  echo "FAIL: rejects allowed REST setup, verification, or cleanup calls" >&2
  exit 1
fi

expected_violations="$(printf '%s\n' \
  '[12:00:00] REST setup POST /wp-json/wp/v2/posts -> 201' \
  '[12:00:01] REST verification PUT /wp-json/wp/v2/pages/456 -> 200' \
  '[12:00:02] REST setup PATCH /wp-json/wp/v2/categories/12 -> 200' \
  '[12:00:03] REST cleanup POST /wp-json/wp/v2/tags -> 201' \
  '[12:00:04] REST verification DELETE /wp-json/wp/v2/posts/789 -> 200')"
assert_equal \
  "$expected_violations" \
  "$(find_forbidden_rest_mutations "$invalid_run_log")" \
  "detects forbidden REST mutations across protected resources and phases"

if find_forbidden_rest_mutations "$TEST_TMP_DIR/missing-events.log" >/dev/null 2>&1; then
  echo "FAIL: reads a missing REST contract event file" >&2
  exit 1
else
  assert_equal "2" "$?" "distinguishes grep errors from a clean contract"
fi

echo "AI E2E contract helper tests passed"
