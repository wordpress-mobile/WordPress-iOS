#!/usr/bin/env bash
# Run AI-driven E2E tests on an iOS Simulator using Claude Code with a
# tightly scoped set of wrapper scripts and runner-side result enforcement.
#
# This script manages the full lifecycle:
#   1. Check for "Testing" label on PR (Buildkite only, skips if missing)
#   2. Download build artifacts and install app (Buildkite only)
#   3. Install Claude Code (if needed)
#   4. Resolve a specific simulator UDID
#   5. Start WebDriverAgent
#   6. Run each markdown test file separately with locked-down wrappers
#   7. Enforce verification / cleanup / final-result contracts per test
#   8. Stop WebDriverAgent and print results
#
# Required environment variables:
#   ANTHROPIC_API_KEY   Claude API key
#   SITE_URL            WordPress test site URL
#   WP_USERNAME         WordPress username
#   WP_APP_PASSWORD     WordPress application password
#
# Optional environment variables:
#   APP                            wordpress | jetpack (default: jetpack)
#   SIMULATOR_NAME                 Simulator to boot if none running (default: iPhone 16)
#   WDA_PORT                       WebDriverAgent port (default: 8100)
#   CLAUDE_MAX_TURNS               Max Claude Code tool-use turns (default: 120)
#   TEST_DIR                       Test directory (default: Tests/AgentTests/ui-tests)
#   CLAUDE_MODEL                   Model to use (default: claude-sonnet-4-20250514)
#   CLAUDE_CODE_EXPECTED_VERSION   Claude Code version to install (default: 2.1.84)
#   CLAUDE_CODE_NPM_SPEC           npm package spec for Claude Code

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"
WDA_STARTED=0

cleanup_wda() {
  if [[ "$WDA_STARTED" -eq 1 ]]; then
    echo "--- Cleanup"
    ruby "$WDA_STOP" --port "$WDA_PORT" 2>/dev/null || true
  fi
}

trap cleanup_wda EXIT

# ── Label gate (Buildkite only) ────────────────────────────────────────
if [[ -n "${BUILDKITE_PULL_REQUEST_LABELS:-}" ]]; then
  echo "--- Checking for 'Testing' label"

  if ! echo ",${BUILDKITE_PULL_REQUEST_LABELS}," | grep -qF ",Testing,"; then
    echo "PR does not have the 'Testing' label. Skipping."
    echo "Add the label and re-run this step to trigger AI E2E tests."
    exit 0
  fi
  echo "'Testing' label found."
fi

# ── Required env vars ──────────────────────────────────────────────────
: "${ANTHROPIC_API_KEY:?Set ANTHROPIC_API_KEY}"
: "${SITE_URL:?Set SITE_URL}"
: "${WP_USERNAME:?Set WP_USERNAME}"
: "${WP_APP_PASSWORD:?Set WP_APP_PASSWORD}"

# ── Defaults ───────────────────────────────────────────────────────────
APP="${APP:-jetpack}"
export SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 16}"
WDA_PORT="${WDA_PORT:-8100}"
CLAUDE_MAX_TURNS="${CLAUDE_MAX_TURNS:-120}"
TEST_DIR="${TEST_DIR:-Tests/AgentTests/ui-tests}"
CLAUDE_MODEL="${CLAUDE_MODEL:-claude-sonnet-4-20250514}"
CLAUDE_CODE_EXPECTED_VERSION="${CLAUDE_CODE_EXPECTED_VERSION:-2.1.84}"
CLAUDE_CODE_NPM_SPEC="${CLAUDE_CODE_NPM_SPEC:-@anthropic-ai/claude-code@${CLAUDE_CODE_EXPECTED_VERSION}}"

case "$APP" in
  wordpress) APP_BUNDLE_ID="org.wordpress" ;;
  jetpack)   APP_BUNDLE_ID="com.automattic.jetpack" ;;
  *) echo "Error: APP must be 'wordpress' or 'jetpack', got '$APP'" >&2; exit 1 ;;
esac
export APP_BUNDLE_ID

# ── Artifact download (Buildkite only) ─────────────────────────────────
if [[ -n "${BUILDKITE:-}" ]]; then
  echo "--- Downloading Build Artifacts"
  download_artifact "build-products-${APP}.tar"
  tar -xf "build-products-${APP}.tar"

  echo "--- Setting up Gems"
  install_gems
fi

if [[ ! -d "$TEST_DIR" ]]; then
  echo "Error: test directory not found: $TEST_DIR" >&2
  exit 1
fi

# ── Locate WDA scripts ─────────────────────────────────────────────────
WDA_START="$REPO_ROOT/.claude/skills/ios-sim-navigation/scripts/wda-start.rb"
WDA_STOP="$REPO_ROOT/.claude/skills/ios-sim-navigation/scripts/wda-stop.rb"

if [[ ! -f "$WDA_START" ]]; then
  echo "Error: WDA start script not found at $WDA_START" >&2
  exit 1
fi

write_result_file() {
  local status="$1"
  local reason="$2"
  local screenshot_rel="${3:-}"

  ruby Scripts/ci/write-ai-test-result.rb \
    "$AI_TEST_RESULT_FILE" \
    "$AI_TEST_TITLE" \
    "$AI_TEST_FILE" \
    "$status" \
    "$reason" \
    "$screenshot_rel"
}

result_field() {
  local key="$1"
  ruby Scripts/ci/read-ai-test-result.rb "$AI_TEST_RESULT_FILE" "$key"
}

recorded_result_count() {
  if [[ -f "$AI_TEST_RESULT_EVENTS_FILE" ]]; then
    awk 'END { print NR + 0 }' "$AI_TEST_RESULT_EVENTS_FILE"
  else
    echo 0
  fi
}

successful_rest_calls() {
  local purpose="$1"
  if [[ -f "$AI_TEST_USAGE_FILE" ]]; then
    awk -F '\t' -v purpose="$purpose" '$1 == purpose && $3 == "1" { count += 1 } END { print count + 0 }' "$AI_TEST_USAGE_FILE"
  else
    echo 0
  fi
}

join_reasons() {
  local joined=""
  local reason
  for reason in "$@"; do
    if [[ -n "$joined" ]]; then
      joined="${joined}; ${reason}"
    else
      joined="$reason"
    fi
  done
  printf '%s' "$joined"
}

# ── Install Claude Code ────────────────────────────────────────────────
if ! command -v claude &>/dev/null || ! claude --version 2>/dev/null | grep -Fq "$CLAUDE_CODE_EXPECTED_VERSION"; then
  echo "--- Installing Claude Code (${CLAUDE_CODE_NPM_SPEC})"
  if ! command -v npm &>/dev/null; then
    echo "npm not found, installing Node.js via Homebrew..."
    brew install node
  fi
  npm install -g "$CLAUDE_CODE_NPM_SPEC"
fi
echo "Claude Code: $(claude --version 2>/dev/null || echo 'unknown')"

# CI permissions are defined explicitly here. Do not rely on
# .claude/settings.json for the Buildkite execution path.
CLAUDE_ALLOWED_TOOLS=(
  --allowedTools "Bash(./Scripts/ci/launch-app.sh)"
  --allowedTools "Bash(./Scripts/ci/wda-curl.sh *)"
  --allowedTools "Bash(./Scripts/ci/wp-api.sh *)"
  --allowedTools "Bash(./Scripts/ci/take-ai-test-screenshot.sh *)"
  --allowedTools "Bash(./Scripts/ci/record-ai-test-result.sh *)"
  --allowedTools "Bash(sleep *)"
)

# ── Resolve simulator ──────────────────────────────────────────────────
echo "--- Setting up Simulator"

SIMULATOR_UDID="$(ruby Scripts/ci/find-booted-simulator.rb "$SIMULATOR_NAME" 2>/dev/null || true)"
if [[ -z "$SIMULATOR_UDID" ]]; then
  echo "No booted simulator named '$SIMULATOR_NAME' found. Booting..."
  xcrun simctl boot "$SIMULATOR_NAME" 2>/dev/null || true
  SIMULATOR_UDID="$(ruby Scripts/ci/find-booted-simulator.rb "$SIMULATOR_NAME" 30 1 2>/dev/null || true)"
fi

if [[ -z "$SIMULATOR_UDID" ]]; then
  echo "Error: could not find a booted simulator named '$SIMULATOR_NAME'" >&2
  exit 1
fi
export SIMULATOR_UDID
echo "Simulator UDID: $SIMULATOR_UDID"

# ── Install app on simulator (Buildkite only) ─────────────────────────
if [[ -n "${BUILDKITE:-}" ]]; then
  APP_DISPLAY_NAME="Jetpack"
  [[ "$APP" = "wordpress" ]] && APP_DISPLAY_NAME="WordPress"

  APP_PATH="$(find DerivedData/Build/Products -name "${APP_DISPLAY_NAME}.app" -path "*Debug-iphonesimulator*" | head -1)"
  if [[ -z "$APP_PATH" ]]; then
    echo "Error: ${APP_DISPLAY_NAME}.app not found in build products" >&2
    exit 1
  fi
  echo "Installing $APP_PATH on simulator..."
  xcrun simctl install "$SIMULATOR_UDID" "$APP_PATH"
fi

# ── Build and start WDA ────────────────────────────────────────────────
echo "--- Building WebDriverAgent"
"$(dirname "$0")/build-wda.sh"

echo "--- Starting WebDriverAgent"
ruby "$WDA_START" --udid "$SIMULATOR_UDID" --port "$WDA_PORT"
WDA_STARTED=1

RESULTS_DIR="Tests/AgentTests/results/$(date +%Y-%m-%d-%H%M)"
RESULTS_JSON_DIR="${RESULTS_DIR}/.results"
RESULT_EVENTS_DIR="${RESULTS_DIR}/.result-events"
USAGE_DIR="${RESULTS_DIR}/.rest-api-usage"
SCREENSHOTS_DIR="${RESULTS_DIR}/screenshots"
mkdir -p "$RESULTS_JSON_DIR" "$RESULT_EVENTS_DIR" "$USAGE_DIR" "$SCREENSHOTS_DIR"

TEST_FILES=()
while IFS= read -r test_file; do
  TEST_FILES+=("$test_file")
done < <(find "$TEST_DIR" -maxdepth 1 -type f -name '*.md' | sort)

if [[ ${#TEST_FILES[@]} -eq 0 ]]; then
  cat > "${RESULTS_DIR}/results.md" <<EOF
# Test Results

- **Date:** $(date +%Y-%m-%d\ %H:%M)
- **App:** ${APP}
- **Site:** ${SITE_URL}
- **Total:** 0 | **Passed:** 0 | **Failed:** 0

## Results

No markdown test files were found in ${TEST_DIR}.
EOF
  echo "Error: no markdown test files found in ${TEST_DIR}" >&2
  exit 1
fi

echo "--- Running AI E2E Tests"

declare -a RESULT_FILES=()
OVERALL_EXIT=0

for index in "${!TEST_FILES[@]}"; do
  AI_TEST_FILE="${TEST_FILES[$index]}"
  AI_TEST_TITLE="$(ruby Scripts/ci/inspect-ai-test-case.rb "$AI_TEST_FILE" title)"
  AI_TEST_SLUG="$(ruby Scripts/ci/inspect-ai-test-case.rb "$AI_TEST_FILE" slug)"
  AI_TEST_RESULT_FILE="${RESULTS_JSON_DIR}/${AI_TEST_SLUG}.json"
  AI_TEST_RESULT_EVENTS_FILE="${RESULT_EVENTS_DIR}/${AI_TEST_SLUG}.log"
  AI_TEST_USAGE_FILE="${USAGE_DIR}/${AI_TEST_SLUG}.log"
  AI_TEST_RESULTS_DIR="$RESULTS_DIR"
  AI_TEST_SCREENSHOTS_DIR="$SCREENSHOTS_DIR"
  export AI_TEST_FILE AI_TEST_TITLE AI_TEST_SLUG AI_TEST_RESULT_FILE AI_TEST_RESULT_EVENTS_FILE AI_TEST_USAGE_FILE AI_TEST_RESULTS_DIR AI_TEST_SCREENSHOTS_DIR

  rm -f "$AI_TEST_RESULT_FILE" "$AI_TEST_RESULT_EVENTS_FILE" "$AI_TEST_USAGE_FILE"

  VERIFICATION_EXPECTED="$(ruby Scripts/ci/inspect-ai-test-case.rb "$AI_TEST_FILE" section-present verification)"
  CLEANUP_EXPECTED="$(ruby Scripts/ci/inspect-ai-test-case.rb "$AI_TEST_FILE" section-present cleanup)"
  export WDA_SESSION_ID=""
  WDA_SESSION_ID="$(ruby Scripts/ci/create-wda-session.rb "$WDA_PORT" 2>/dev/null || true)"

  echo
  echo "============================================================"
  echo "[$((index + 1))/${#TEST_FILES[@]}] ${AI_TEST_TITLE}"
  echo "============================================================"

  if [[ -z "$WDA_SESSION_ID" ]]; then
    write_result_file fail "Failed to create a WebDriverAgent session before test execution"
    RESULT_FILES+=("$AI_TEST_RESULT_FILE")
    OVERALL_EXIT=1
    continue
  fi
  export WDA_SESSION_ID

  TEST_CONTENT="$(cat "$AI_TEST_FILE")"
  PROMPT="$(cat <<EOF
Execute exactly one AI-driven iOS UI test case against the ${APP} app.

Environment:
- App bundle ID: ${APP_BUNDLE_ID}
- Simulator UDID: ${SIMULATOR_UDID}
- WDA Port: ${WDA_PORT}
- WDA Session ID: ${WDA_SESSION_ID}
- Site URL: ${SITE_URL}
- Username: ${WP_USERNAME}
- Verification required: $( [[ "$VERIFICATION_EXPECTED" == "1" ]] && echo yes || echo no )
- Cleanup required: $( [[ "$CLEANUP_EXPECTED" == "1" ]] && echo yes || echo no )

Available commands:
- ./Scripts/ci/launch-app.sh
- ./Scripts/ci/wda-curl.sh METHOD PATH [JSON_BODY]
- ./Scripts/ci/wp-api.sh PURPOSE METHOD PATH [JSON_BODY]
- ./Scripts/ci/take-ai-test-screenshot.sh LABEL
- ./Scripts/ci/record-ai-test-result.sh STATUS REASON [SCREENSHOT_RELATIVE_PATH]
- sleep N

Rules:
- Start by running ./Scripts/ci/launch-app.sh, then sleep 3, then fetch the accessibility tree.
- Use the accessibility tree instead of screenshots whenever possible.
- Use wp-api.sh with purpose=setup for prerequisites, purpose=verification for verification work, and purpose=cleanup for cleanup work.
- If you fail the test, take a screenshot first and pass the returned relative path to record-ai-test-result.sh.
- You must call record-ai-test-result.sh exactly once before you stop.
- Keep reasons short and single-line so they are safe to store in CI output.

Test case:

${TEST_CONTENT}
EOF
)"

  CLAUDE_EXIT=0
  claude --print \
    --model "$CLAUDE_MODEL" \
    --max-turns "$CLAUDE_MAX_TURNS" \
    "${CLAUDE_ALLOWED_TOOLS[@]}" \
    --prompt "$PROMPT" \
    || CLAUDE_EXIT=$?

  declare -a ENFORCEMENT_REASONS=()
  if [[ $CLAUDE_EXIT -ne 0 ]]; then
    ENFORCEMENT_REASONS+=("Claude exited with code ${CLAUDE_EXIT}")
  fi

  RESULT_CALLS="$(recorded_result_count)"
  if [[ "$RESULT_CALLS" -eq 0 ]]; then
    ENFORCEMENT_REASONS+=('Claude did not record a final result')
  elif [[ "$RESULT_CALLS" -gt 1 ]]; then
    ENFORCEMENT_REASONS+=('Claude recorded multiple final results')
  fi

  if [[ "$VERIFICATION_EXPECTED" == "1" && "$(successful_rest_calls verification)" -eq 0 ]]; then
    ENFORCEMENT_REASONS+=('verification section was declared but no successful verification REST call completed')
  fi

  if [[ "$CLEANUP_EXPECTED" == "1" && "$(successful_rest_calls cleanup)" -eq 0 ]]; then
    ENFORCEMENT_REASONS+=('cleanup section was declared but no successful cleanup REST call completed')
  fi

  if [[ ! -f "$AI_TEST_RESULT_FILE" ]]; then
    write_result_file fail "$(join_reasons "${ENFORCEMENT_REASONS[@]}")"
  elif [[ ${#ENFORCEMENT_REASONS[@]} -gt 0 ]]; then
    CURRENT_REASON="$(result_field reason)"
    CURRENT_SCREENSHOT="$(result_field screenshot)"
    if [[ -n "$CURRENT_REASON" ]]; then
      ENFORCED_REASON="${CURRENT_REASON}. Runner enforcement: $(join_reasons "${ENFORCEMENT_REASONS[@]}")"
    else
      ENFORCED_REASON="Runner enforcement: $(join_reasons "${ENFORCEMENT_REASONS[@]}")"
    fi
    write_result_file fail "$ENFORCED_REASON" "$CURRENT_SCREENSHOT"
  fi

  RESULT_STATUS="$(result_field status)"
  RESULT_REASON="$(result_field reason)"
  echo "[${RESULT_STATUS^^}] ${AI_TEST_TITLE}"
  echo "  ${RESULT_REASON}"

  if [[ "$RESULT_STATUS" != "pass" ]]; then
    OVERALL_EXIT=1
  fi

  RESULT_FILES+=("$AI_TEST_RESULT_FILE")
done

ruby Scripts/ci/assemble-ai-test-results.rb "$RESULTS_DIR" "$APP" "$SITE_URL" "${RESULT_FILES[@]}"

# ── Report results ─────────────────────────────────────────────────────
echo "--- Results"
cat "${RESULTS_DIR}/results.md"

exit "$OVERALL_EXIT"
