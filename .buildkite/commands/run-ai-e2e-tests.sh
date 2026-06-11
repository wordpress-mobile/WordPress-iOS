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

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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

preflight_test_site() {
  local api_root_url
  local current_user_url

  echo "--- Preflighting AI E2E Test Site"

  api_root_url="$(site_url_with_path "$SIMULATOR_LLM_PILOT_SITE_URL" "/wp-json/")"
  current_user_url="$(site_url_with_path "$SIMULATOR_LLM_PILOT_SITE_URL" "/wp-json/wp/v2/users/me")"

  preflight_endpoint "REST API root" "$api_root_url" preflight_rest_api_root
  preflight_endpoint "authenticated current user endpoint" "$current_user_url" preflight_current_user_auth "authenticated"
}

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
validate_https_site_url "$SIMULATOR_LLM_PILOT_SITE_URL"

PREFLIGHT_TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/preflight.XXXXXX" 2>/dev/null || mktemp -d -t preflight)"
trap 'rm -rf "$PREFLIGHT_TMP_DIR"' EXIT
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
"$(dirname "$0")/build-wda.sh"

# ── Run tests ────────────────────────────────────────────────────────
echo "--- Running AI E2E Tests"

TIMESTAMP="$(date +%Y-%m-%d-%H%M)"
RESULTS_DIR="Tests/AgentTests/results/${TIMESTAMP}"

EXIT_CODE=0
simulator-llm-pilot run "$TEST_DIR" \
  --app-bundle-id "$APP_BUNDLE_ID" \
  --app-name "$APP_DISPLAY_NAME" \
  --app-instructions-file "$APP_INSTRUCTIONS_FILE" \
  --simulator-udid "$UDID" \
  --results-dir "$RESULTS_DIR" \
  || EXIT_CODE=$?

# ── Report results ───────────────────────────────────────────────────
echo "--- Results"
RESULTS_FILE="${RESULTS_DIR}/results.md"
if [[ -f "$RESULTS_FILE" ]]; then
  cat "$RESULTS_FILE"
else
  echo "Warning: no results.md found at $RESULTS_FILE"
fi

exit "$EXIT_CODE"
