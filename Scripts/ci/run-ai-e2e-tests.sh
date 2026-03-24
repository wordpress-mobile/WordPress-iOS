#!/usr/bin/env bash
# Run AI-driven E2E tests on an iOS Simulator using Claude Code.
#
# This script manages the full lifecycle:
#   1. Install Claude Code (if needed)
#   2. Detect or boot a simulator
#   3. Start WebDriverAgent and create a session
#   4. Run Claude Code with a locked-down tool allowlist
#   5. Stop WebDriverAgent
#   6. Exit with the test result code
#
# Required environment variables:
#   ANTHROPIC_API_KEY   Claude API key
#   SITE_URL            WordPress test site URL
#   WP_USERNAME         WordPress username
#   WP_APP_PASSWORD     WordPress application password
#
# Optional environment variables:
#   APP                 wordpress | jetpack (default: jetpack)
#   SIMULATOR_NAME      Simulator to boot if none running (default: iPhone 16)
#   WDA_PORT            WebDriverAgent port (default: 8100)
#   CLAUDE_MAX_TURNS    Max Claude Code tool-use turns (default: 200)
#   TEST_DIR            Test directory (default: Tests/AgentTests/ui-tests)
#   CLAUDE_MODEL        Model to use (default: claude-sonnet-4-20250514)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

# ── Required env vars ────────────────────────────────────────────────
: "${ANTHROPIC_API_KEY:?Set ANTHROPIC_API_KEY}"
: "${SITE_URL:?Set SITE_URL}"
: "${WP_USERNAME:?Set WP_USERNAME}"
: "${WP_APP_PASSWORD:?Set WP_APP_PASSWORD}"

# ── Defaults ─────────────────────────────────────────────────────────
APP="${APP:-jetpack}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 16}"
WDA_PORT="${WDA_PORT:-8100}"
CLAUDE_MAX_TURNS="${CLAUDE_MAX_TURNS:-200}"
TEST_DIR="${TEST_DIR:-Tests/AgentTests/ui-tests}"
CLAUDE_MODEL="${CLAUDE_MODEL:-claude-sonnet-4-20250514}"

case "$APP" in
  wordpress) BUNDLE_ID="org.wordpress" ;;
  jetpack)   BUNDLE_ID="com.automattic.jetpack" ;;
  *) echo "Error: APP must be 'wordpress' or 'jetpack', got '$APP'" >&2; exit 1 ;;
esac

# ── Locate WDA scripts ──────────────────────────────────────────────
WDA_START="$REPO_ROOT/.claude/skills/ios-sim-navigation/scripts/wda-start.rb"
WDA_STOP="$REPO_ROOT/.claude/skills/ios-sim-navigation/scripts/wda-stop.rb"

if [ ! -f "$WDA_START" ]; then
  echo "Error: WDA start script not found at $WDA_START" >&2
  exit 1
fi

# ── Step 1: Install Claude Code ─────────────────────────────────────
if ! command -v claude &>/dev/null; then
  echo "Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code
fi
echo "Claude Code: $(claude --version 2>/dev/null || echo 'unknown')"

# ── Step 2: Detect or boot simulator ────────────────────────────────
get_booted_udid() {
  xcrun simctl list devices booted -j 2>/dev/null \
    | ruby -rjson -e '
        data = JSON.parse(STDIN.read)
        data.fetch("devices", {}).each_value do |devs|
          devs.each { |d| (puts d["udid"]; exit) if d["state"] == "Booted" }
        end
      ' 2>/dev/null || true
}

UDID="$(get_booted_udid)"

if [ -z "$UDID" ]; then
  echo "No booted simulator found. Booting '$SIMULATOR_NAME'..."
  xcrun simctl boot "$SIMULATOR_NAME"
  sleep 5
  UDID="$(get_booted_udid)"
fi

if [ -z "$UDID" ]; then
  echo "Error: could not find a booted simulator" >&2
  exit 1
fi
echo "Simulator UDID: $UDID"

# ── Step 3: Start WDA ───────────────────────────────────────────────
echo "Starting WebDriverAgent on port $WDA_PORT..."
ruby "$WDA_START" --udid "$UDID" --port "$WDA_PORT"

# Create a WDA session
SESSION_ID="$(curl -s -X POST "http://localhost:${WDA_PORT}/session" \
  -H 'Content-Type: application/json' \
  -d '{"capabilities":{"alwaysMatch":{}}}' \
  | ruby -rjson -e 'puts JSON.parse(STDIN.read).dig("value", "sessionId")')"

if [ -z "$SESSION_ID" ]; then
  echo "Error: failed to create WDA session" >&2
  ruby "$WDA_STOP" --port "$WDA_PORT" 2>/dev/null || true
  exit 1
fi
echo "WDA Session: $SESSION_ID"

# ── Step 4: Export env vars for wrapper scripts and Claude ───────────
export SIMULATOR_UDID="$UDID"
export WDA_SESSION_ID="$SESSION_ID"
export WDA_PORT
export APP_BUNDLE_ID="$BUNDLE_ID"
export SITE_URL
export WP_USERNAME
export WP_APP_PASSWORD

# ── Step 5: Prepare results directory ────────────────────────────────
TIMESTAMP="$(date +%Y-%m-%d-%H%M)"
RESULTS_DIR="Tests/AgentTests/results/${TIMESTAMP}"
mkdir -p "$RESULTS_DIR"

# ── Step 6: Run Claude Code ──────────────────────────────────────────
PROMPT="Run all AI E2E test cases in ${TEST_DIR}/ using the ci-test-runner skill.

Environment (already set as env vars, also available to wrapper scripts):
- App: ${APP} (bundle ID: ${BUNDLE_ID})
- Simulator UDID: ${UDID}
- WDA Session ID: ${SESSION_ID}
- WDA Port: ${WDA_PORT}
- Site URL: ${SITE_URL}
- Username: ${WP_USERNAME}
- Results directory: ${RESULTS_DIR}
- Screenshots directory: ${RESULTS_DIR}/screenshots"

CLAUDE_EXIT=0
claude --print \
  --model "$CLAUDE_MODEL" \
  --max-turns "$CLAUDE_MAX_TURNS" \
  --allowedTools "Read" \
  --allowedTools "Glob(Tests/AgentTests/**)" \
  --allowedTools "Write(Tests/AgentTests/results/*)" \
  --allowedTools "Bash(./Scripts/ci/wda-curl.sh *)" \
  --allowedTools "Bash(./Scripts/ci/wp-api.sh *)" \
  --allowedTools "Bash(./Scripts/ci/launch-app.sh)" \
  --allowedTools "Bash(xcrun simctl terminate *)" \
  --allowedTools "Bash(xcrun simctl io * screenshot Tests/AgentTests/results/*)" \
  --allowedTools "Bash(sleep *)" \
  --allowedTools "Bash(mkdir -p Tests/AgentTests/results/*)" \
  --prompt "$PROMPT" \
  || CLAUDE_EXIT=$?

# ── Step 7: Stop WDA ────────────────────────────────────────────────
echo "Stopping WebDriverAgent..."
ruby "$WDA_STOP" --port "$WDA_PORT" 2>/dev/null || true

# ── Step 8: Report results ───────────────────────────────────────────
RESULTS_FILE="${RESULTS_DIR}/results.md"
if [ -f "$RESULTS_FILE" ]; then
  echo ""
  echo "═══════════════════════════════════════"
  echo "  Test Results: ${RESULTS_DIR}/results.md"
  echo "═══════════════════════════════════════"
  echo ""
  cat "$RESULTS_FILE"
else
  echo "Warning: no results.md found at $RESULTS_FILE"
fi

exit "$CLAUDE_EXIT"
