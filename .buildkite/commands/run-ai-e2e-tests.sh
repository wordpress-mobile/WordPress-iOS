#!/usr/bin/env bash
# Run AI-driven E2E tests on an iOS Simulator using simulator-llm-pilot.
#
# This script manages the full lifecycle:
#   1. Check for "Testing" label on PR (Buildkite only, skips if missing)
#   2. Download build artifacts and install app (Buildkite only)
#   3. Install the simulator-llm-pilot gem from GitHub
#   4. Run tests (gem handles simulator, WDA, agent loop, and results)
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

# ── Defaults ─────────────────────────────────────────────────────────
APP="${APP:-jetpack}"
export SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 16}"
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
