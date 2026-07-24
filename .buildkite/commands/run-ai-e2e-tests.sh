#!/usr/bin/env bash
# Run AI-driven E2E tests on an iOS Simulator using simulator-llm-pilot.
#
# This script manages the full lifecycle:
#   1. Check for "Testing" label on PR (Buildkite only, skips if missing)
#   2. Preflight the configured WordPress test site
#   3. Download build artifacts and install app (Buildkite only)
#   4. Install the simulator-llm-pilot gem from GitHub
#   5. Run tests (gem handles simulator, WDA, agent loop, and results)
#
# The gem provides a sandboxed agent that drives the simulator through a
# fixed set of tools (tap, swipe, type, REST API, etc.) — no arbitrary
# code execution, no shell access.
#
# Required environment variables:
#   ANTHROPIC_API_KEY                  Claude API key
#   SIMULATOR_LLM_PILOT_SITE_URL      WordPress test site URL
#   SIMULATOR_LLM_PILOT_USERNAME      WordPress username
#   SIMULATOR_LLM_PILOT_APP_PASSWORD  WordPress application password
#
# Optional environment variables:
#   APP                            wordpress | jetpack (default: jetpack)
#   SIMULATOR_NAME                 Simulator to boot if none running (default: iPhone 16)
#   TEST_DIR                       Test directory (default: Tests/AgentTests/ui-tests)
#   SIMULATOR_LLM_PILOT_REPO_URL   Remote repo URL for simulator-llm-pilot
#   SIMULATOR_LLM_PILOT_SOURCE_PATH Local source checkout override for simulator-llm-pilot
#   SIMULATOR_LLM_PILOT_EXPECT_XMLRPC_AVAILABILITY
#                                  unavailable | available | any
#                                  (default: unavailable in Buildkite, any locally)
#   SIMULATOR_LLM_PILOT_EXPECT_XMLRPC_UNAVAILABLE_HTTP_STATUS
#                                  Optional exact HTTP status that represents
#                                  XML-RPC being blocked before WordPress

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

normalize_site_url() {
  local site_url="$1"
  if [[ "$site_url" == http://* || "$site_url" == https://* ]]; then
    printf '%s' "$site_url"
  else
    printf 'https://%s' "$site_url"
  fi
}

validate_https_site_url() {
  local site_url="$1"
  if [[ "$site_url" == https://* ]]; then
    return 0
  fi

  echo "Error: SIMULATOR_LLM_PILOT_SITE_URL must use https://." >&2
  echo "The AI E2E tests send an application password via HTTP Basic Auth for REST API setup and verification." >&2
  echo "Configured URL: ${site_url}" >&2
  return 1
}

site_url_with_path() {
  local site_url="${1%/}"
  local path="$2"
  printf '%s%s' "$site_url" "$path"
}

preflight_current_user_auth() {
  local body_file="$1"
  grep -q '"id"[[:space:]]*:' "$body_file"
}

preflight_rest_api_root() {
  local body_file="$1"
  grep -q '"namespaces"[[:space:]]*:' "$body_file" && grep -q '"routes"[[:space:]]*:' "$body_file"
}

validate_expected_xmlrpc_availability() {
  local expected_availability="$1"

  case "$expected_availability" in
    unavailable | available | any) ;;
    *)
      echo "Error: SIMULATOR_LLM_PILOT_EXPECT_XMLRPC_AVAILABILITY must be 'unavailable', 'available', or 'any'." >&2
      echo "Configured value: ${expected_availability}" >&2
      return 1
      ;;
  esac
}

validate_expected_xmlrpc_unavailable_http_status() {
  local expected_status="$1"

  case "$expected_status" in
    "" | 429) ;;
    *)
      echo "Error: SIMULATOR_LLM_PILOT_EXPECT_XMLRPC_UNAVAILABLE_HTTP_STATUS must be empty or 429." >&2
      echo "Configured value: ${expected_status}" >&2
      return 1
      ;;
  esac
}

default_expected_xmlrpc_availability() {
  if [[ -n "${BUILDKITE:-}" ]]; then
    printf 'unavailable'
  else
    printf 'any'
  fi
}

xmlrpc_fault_code() {
  local body_file="$1"
  local compact_response
  local fault_code_pattern='<name>faultCode</name><value><(int|i4)>([0-9]+)</(int|i4)></value>'

  compact_response="$(tr -d '[:space:]' < "$body_file")"
  if [[ "$compact_response" =~ $fault_code_pattern ]]; then
    printf '%s' "${BASH_REMATCH[2]}"
    return 0
  fi

  return 1
}

detect_xmlrpc_availability() {
  local body_file="$1"
  local http_status="$2"
  local content_type="$3"
  local fault_code

  if ! fault_code="$(xmlrpc_fault_code "$body_file")"; then
    fault_code=""
  fi

  if [[ "$content_type" == text/xml* && "$fault_code" == "405" ]]; then
    printf 'unavailable'
  elif [[ "$http_status" == 2* && "$content_type" == text/xml* ]] &&
    grep -q '<methodResponse>' "$body_file"; then
    printf 'available'
  else
    printf 'unknown'
  fi
}

find_forbidden_rest_mutations() {
  local events_file="$1"

  grep -E 'REST ((setup|verification) (POST|PUT|PATCH|DELETE)|cleanup (POST|PUT|PATCH)) /wp-json/wp/v2/(posts|pages|categories|tags)([/?[:space:]]|$)' "$events_file"
}

capture_rest_contract_events() {
  local events_file="$1"

  : > "$events_file"
  awk -v events_file="$events_file" '
    {
      print
      fflush()

      line = $0
      escape = sprintf("%c", 27)
      gsub(escape "\\[[0-9;]*[[:alpha:]]", "", line)
      if (line ~ /REST (setup|verification|cleanup) [A-Z]+ \/wp-json\/wp\/v2\/[^[:space:]]+ -> [0-9][0-9][0-9]$/) {
        print line >> events_file
        fflush(events_file)
      }
    }
  '
}

validate_simulator_llm_pilot_rest_log_contract() {
  local executor_file="${1:-}"
  local expected_logger='@logger.info "  REST #{purpose} #{method} #{path} -> #{response.code}"'

  if [[ -z "$executor_file" ]]; then
    if ! executor_file="$(
      ruby -e '
        spec = Gem::Specification.find_by_name("simulator-llm-pilot")
        print File.join(spec.full_gem_path, "lib/simulator_llm_pilot/tool_executor.rb")
      ' 2>/dev/null
    )"; then
      echo "Error: unable to locate the installed simulator-llm-pilot gem." >&2
      return 1
    fi
  fi

  if [[ ! -r "$executor_file" ]]; then
    echo "Error: simulator-llm-pilot REST logger source is not readable: ${executor_file}" >&2
    return 1
  fi

  if ! grep -Fq "$expected_logger" "$executor_file"; then
    echo "Error: simulator-llm-pilot REST log format changed." >&2
    echo "Update the AI E2E REST contract parser before running the suite." >&2
    echo "Source: ${executor_file}" >&2
    return 1
  fi

  echo "OK: simulator-llm-pilot REST log format is compatible"
}

preflight_endpoint() {
  local label="$1"
  local url="$2"
  local body_check="$3"
  local auth_mode="${4:-anonymous}"
  local body_file
  local curl_args
  local curl_output
  local http_status
  local effective_url
  local redirect_count

  body_file="$(mktemp "${PREFLIGHT_TMP_DIR}/body.XXXXXX")"

  curl_args=(
    --silent
    --show-error
    --location
    --max-redirs 3
    --connect-timeout 10
    --max-time 20
    --proto '=https'
    --proto-redir '=https'
    --output "$body_file"
    --write-out "%{http_code} %{url_effective} %{num_redirects}"
  )

  if [[ "$auth_mode" == "authenticated" ]]; then
    curl_args+=(--user "${SIMULATOR_LLM_PILOT_USERNAME}:${SIMULATOR_LLM_PILOT_APP_PASSWORD}")
  fi

  curl_args+=("$url")

  if ! curl_output="$(curl "${curl_args[@]}")"; then
    echo "Error: unable to reach ${label} at ${url}" >&2
    return 1
  fi

  read -r http_status effective_url redirect_count <<< "$curl_output"

  if [[ "$effective_url" == *"wordpress.com/typo"* ]]; then
    echo "Error: ${label} redirected to WordPress.com typo handling." >&2
    echo "Configured URL: ${url}" >&2
    echo "Final URL: ${effective_url}" >&2
    echo "The AI E2E test site is likely missing or no longer mapped." >&2
    return 1
  fi

  if [[ "$http_status" != 2* ]]; then
    echo "Error: ${label} returned HTTP ${http_status}." >&2
    echo "URL: ${url}" >&2
    if [[ "$redirect_count" != "0" ]]; then
      echo "Final URL after ${redirect_count} redirect(s): ${effective_url}" >&2
    fi
    if [[ "$auth_mode" == "authenticated" && "$http_status" == "401" ]]; then
      echo "Check SIMULATOR_LLM_PILOT_USERNAME and SIMULATOR_LLM_PILOT_APP_PASSWORD." >&2
    fi
    return 1
  fi

  if ! "$body_check" "$body_file"; then
    echo "Error: ${label} returned HTTP ${http_status}, but the response does not look like the expected WordPress REST API response." >&2
    echo "URL: ${url}" >&2
    if [[ "$redirect_count" != "0" ]]; then
      echo "Final URL after ${redirect_count} redirect(s): ${effective_url}" >&2
    fi
    return 1
  fi

  echo "OK: ${label} returned HTTP ${http_status}"
}

preflight_xmlrpc_availability() {
  local site_url="$1"
  local expected_availability="$2"
  local expected_unavailable_http_status="${3:-}"
  local xmlrpc_url
  local body_file
  local curl_output
  local http_status
  local effective_url
  local redirect_count
  local content_type
  local detected_availability
  local availability_detail=""
  local request_body

  xmlrpc_url="$(site_url_with_path "$site_url" "/xmlrpc.php")"
  body_file="$(mktemp "${PREFLIGHT_TMP_DIR}/xmlrpc.XXXXXX")"
  request_body='<?xml version="1.0"?><methodCall><methodName>wp.getOptions</methodName><params><param><value><int>0</int></value></param><param><value><string>ai-e2e-preflight</string></value></param><param><value><string>invalid</string></value></param></params></methodCall>'

  if ! curl_output="$(
    curl \
      --silent \
      --show-error \
      --connect-timeout 10 \
      --max-time 20 \
      --proto '=https' \
      --request POST \
      --header 'Content-Type: text/xml' \
      --data-binary "$request_body" \
      --output "$body_file" \
      --write-out "%{http_code} %{url_effective} %{num_redirects} %{content_type}" \
      "$xmlrpc_url"
  )"; then
    echo "Error: unable to probe XML-RPC at ${xmlrpc_url}" >&2
    return 1
  fi

  read -r http_status effective_url redirect_count content_type <<< "$curl_output"

  if [[ "$http_status" == 3* ]]; then
    echo "Error: XML-RPC probe returned HTTP ${http_status}; redirects are not followed." >&2
    echo "URL: ${xmlrpc_url}" >&2
    return 1
  fi

  if [[ "$effective_url" == *"wordpress.com/typo"* ]]; then
    echo "Error: XML-RPC probe redirected to WordPress.com typo handling." >&2
    echo "Configured URL: ${xmlrpc_url}" >&2
    echo "Final URL: ${effective_url}" >&2
    return 1
  fi

  if [[ -n "$expected_unavailable_http_status" && "$http_status" == "$expected_unavailable_http_status" ]]; then
    detected_availability="unavailable"
    availability_detail=" via expected HTTP ${http_status}"
  else
    detected_availability="$(detect_xmlrpc_availability "$body_file" "$http_status" "$content_type")"
  fi

  if [[ "$detected_availability" == "unknown" ]]; then
    echo "Error: unable to determine the test site's XML-RPC availability." >&2
    echo "URL: ${xmlrpc_url}" >&2
    echo "HTTP status: ${http_status}" >&2
    echo "Content-Type: ${content_type:-<missing>}" >&2
    if [[ "$redirect_count" != "0" ]]; then
      echo "Final URL after ${redirect_count} redirect(s): ${effective_url}" >&2
    fi
    return 1
  fi

  if [[ "$expected_availability" != "any" && "$detected_availability" != "$expected_availability" ]]; then
    echo "Error: AI E2E test site XML-RPC availability drifted." >&2
    echo "Expected: ${expected_availability}" >&2
    echo "Detected: ${detected_availability}" >&2
    echo "URL: ${xmlrpc_url}" >&2
    return 1
  fi

  echo "OK: XML-RPC is ${detected_availability}${availability_detail}"
}

preflight_test_site() {
  local api_root_url
  local current_user_url

  echo "--- Preflighting AI E2E Test Site"

  api_root_url="$(site_url_with_path "$SIMULATOR_LLM_PILOT_SITE_URL" "/wp-json/")"
  current_user_url="$(site_url_with_path "$SIMULATOR_LLM_PILOT_SITE_URL" "/wp-json/wp/v2/users/me")"

  preflight_endpoint "REST API root" "$api_root_url" preflight_rest_api_root
  preflight_endpoint "authenticated current user endpoint" "$current_user_url" preflight_current_user_auth "authenticated"
  preflight_xmlrpc_availability \
    "$SIMULATOR_LLM_PILOT_SITE_URL" \
    "$SIMULATOR_LLM_PILOT_EXPECT_XMLRPC_AVAILABILITY" \
    "$SIMULATOR_LLM_PILOT_EXPECT_XMLRPC_UNAVAILABLE_HTTP_STATUS"
}

main() {
# ── Label gate (Buildkite only) ─────────────────────────────────────
if [[ -n "${BUILDKITE_PULL_REQUEST_LABELS:-}" ]]; then
  echo "--- Checking for 'Testing' label"

  if ! echo ",${BUILDKITE_PULL_REQUEST_LABELS}," | grep -qF ",Testing,"; then
    echo "PR does not have the 'Testing' label. Skipping."
    echo "Add the label and re-run this step to trigger AI E2E tests."
    exit 0
  fi
  echo "'Testing' label found."
fi

# ── Required env vars ────────────────────────────────────────────────
: "${ANTHROPIC_API_KEY:?Set ANTHROPIC_API_KEY}"
: "${SIMULATOR_LLM_PILOT_SITE_URL:?Set SIMULATOR_LLM_PILOT_SITE_URL}"
: "${SIMULATOR_LLM_PILOT_USERNAME:?Set SIMULATOR_LLM_PILOT_USERNAME}"
: "${SIMULATOR_LLM_PILOT_APP_PASSWORD:?Set SIMULATOR_LLM_PILOT_APP_PASSWORD}"
export SIMULATOR_LLM_PILOT_SITE_URL="$(normalize_site_url "$SIMULATOR_LLM_PILOT_SITE_URL")"
export SIMULATOR_LLM_PILOT_EXPECT_XMLRPC_AVAILABILITY="${SIMULATOR_LLM_PILOT_EXPECT_XMLRPC_AVAILABILITY:-$(default_expected_xmlrpc_availability)}"
export SIMULATOR_LLM_PILOT_EXPECT_XMLRPC_UNAVAILABLE_HTTP_STATUS="${SIMULATOR_LLM_PILOT_EXPECT_XMLRPC_UNAVAILABLE_HTTP_STATUS:-}"
validate_https_site_url "$SIMULATOR_LLM_PILOT_SITE_URL"
validate_expected_xmlrpc_availability "$SIMULATOR_LLM_PILOT_EXPECT_XMLRPC_AVAILABILITY"
validate_expected_xmlrpc_unavailable_http_status "$SIMULATOR_LLM_PILOT_EXPECT_XMLRPC_UNAVAILABLE_HTTP_STATUS"

PREFLIGHT_TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/preflight.XXXXXX" 2>/dev/null || mktemp -d -t preflight)"
trap 'rm -rf "$PREFLIGHT_TMP_DIR"' EXIT

echo "--- Testing AI E2E Contracts"
bash Tests/AgentTests/test-ai-e2e-contracts.sh

preflight_test_site

# ── Defaults ─────────────────────────────────────────────────────────
APP="${APP:-jetpack}"
export SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17}"
TEST_DIR="${TEST_DIR:-Tests/AgentTests/ui-tests}"
SIMULATOR_LLM_PILOT_REPO_URL="${SIMULATOR_LLM_PILOT_REPO_URL:-https://github.com/Automattic/simulator-llm-pilot.git}"
SIMULATOR_LLM_PILOT_SOURCE_PATH="${SIMULATOR_LLM_PILOT_SOURCE_PATH:-}"

case "$APP" in
  wordpress) APP_BUNDLE_ID="org.wordpress"; APP_DISPLAY_NAME="WordPress" ;;
  jetpack)   APP_BUNDLE_ID="com.automattic.jetpack"; APP_DISPLAY_NAME="Jetpack" ;;
  *) echo "Error: APP must be 'wordpress' or 'jetpack', got '$APP'" >&2; exit 1 ;;
esac

APP_INSTRUCTIONS_FILE="${REPO_ROOT}/Tests/AgentTests/app-instructions.md"

# ── Artifact download (Buildkite only) ───────────────────────────────
if [[ -n "${BUILDKITE:-}" ]]; then
  echo "--- Downloading Build Artifacts"
  download_artifact "build-products-${APP}.tar"
  tar -xf "build-products-${APP}.tar"

  echo "--- Setting up Gems"
  install_gems
fi

# ── Install simulator-llm-pilot ──────────────────────────────────────
echo "--- Installing simulator-llm-pilot"
bash Scripts/ci/install-simulator-llm-pilot.sh
echo "simulator-llm-pilot $(simulator-llm-pilot version)"
validate_simulator_llm_pilot_rest_log_contract

# ── Resolve simulator and install app (Buildkite only) ───────────────
echo "--- Setting up Simulator"

UDID="$(ruby Scripts/ci/find-booted-simulator.rb "$SIMULATOR_NAME" 2>/dev/null || true)"
if [[ -z "$UDID" ]]; then
  echo "No booted simulator named '$SIMULATOR_NAME' found. Booting..."
  xcrun simctl boot "$SIMULATOR_NAME" 2>/dev/null || true
  UDID="$(ruby Scripts/ci/find-booted-simulator.rb "$SIMULATOR_NAME" 30 1 2>/dev/null || true)"
fi

if [[ -z "$UDID" ]]; then
  echo "Error: could not find a booted simulator named '$SIMULATOR_NAME'" >&2
  exit 1
fi

export SIMULATOR_UDID="$UDID"
echo "Simulator UDID: $UDID"

if [[ -n "${BUILDKITE:-}" ]]; then
  APP_PATH=$(find DerivedData/Build/Products -name "${APP_DISPLAY_NAME}.app" -path "*Debug-iphonesimulator*" | head -1)
  if [[ -z "$APP_PATH" ]]; then
    echo "Error: ${APP_DISPLAY_NAME}.app not found in build products" >&2
    exit 1
  fi
  echo "Installing $APP_PATH on simulator..."
  xcrun simctl install "$UDID" "$APP_PATH"
fi

# ── Build WebDriverAgent (if not present) ────────────────────────────
echo "--- Building WebDriverAgent"
"$SCRIPT_DIR/build-wda.sh"

# ── Run tests ────────────────────────────────────────────────────────
echo "--- Running AI E2E Tests"

TIMESTAMP="$(date +%Y-%m-%d-%H%M)"
RESULTS_DIR="Tests/AgentTests/results/${TIMESTAMP}"
# Keep the full runner output in the access-controlled Buildkite log. Persist
# only method/path/status contract events in this temporary, non-artifact file.
REST_CONTRACT_EVENTS_FILE="${PREFLIGHT_TMP_DIR}/rest-contract-events.log"
mkdir -p "$RESULTS_DIR"

set +e
simulator-llm-pilot run "$TEST_DIR" \
  --app-bundle-id "$APP_BUNDLE_ID" \
  --app-name "$APP_DISPLAY_NAME" \
  --app-instructions-file "$APP_INSTRUCTIONS_FILE" \
  --simulator-udid "$UDID" \
  --results-dir "$RESULTS_DIR" \
  2>&1 | capture_rest_contract_events "$REST_CONTRACT_EVENTS_FILE"
PIPELINE_STATUS=("${PIPESTATUS[@]}")
set -e

EXIT_CODE="${PIPELINE_STATUS[0]}"
if [[ "${PIPELINE_STATUS[1]}" -ne 0 ]]; then
  echo "Error: unable to inspect the AI E2E REST contract events." >&2
  EXIT_CODE=1
fi

if FORBIDDEN_REST_MUTATIONS="$(find_forbidden_rest_mutations "$REST_CONTRACT_EVENTS_FILE")"; then
  echo "--- AI E2E Contract Violations"
  echo "Error: REST mutations replaced an app UI action under test." >&2
  printf '%s\n' "$FORBIDDEN_REST_MUTATIONS" >&2
  EXIT_CODE=1
else
  GREP_STATUS=$?
  if [[ "$GREP_STATUS" -ne 1 ]]; then
    echo "Error: unable to read the AI E2E REST contract events." >&2
    EXIT_CODE=1
  fi
fi

# ── Report results ───────────────────────────────────────────────────
echo "--- Results"
RESULTS_FILE="${RESULTS_DIR}/results.md"
if [[ -f "$RESULTS_FILE" ]]; then
  cat "$RESULTS_FILE"
else
  echo "Warning: no results.md found at $RESULTS_FILE"
fi

exit "$EXIT_CODE"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
