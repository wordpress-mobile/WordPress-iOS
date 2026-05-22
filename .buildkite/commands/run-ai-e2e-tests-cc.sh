#!/usr/bin/env bash

set -euo pipefail

APP="${APP:-jetpack}"

case "$APP" in
  wordpress) APP_DISPLAY_NAME="WordPress" ;;
  jetpack)   APP_DISPLAY_NAME="Jetpack" ;;
  *) echo "Error: APP must be 'wordpress' or 'jetpack', got '$APP'" >&2; exit 1 ;;
esac

echo "--- :key: Validating Test Site Credentials"
if [[ "$SIMULATOR_LLM_PILOT_SITE_URL" != http://* && "$SIMULATOR_LLM_PILOT_SITE_URL" != https://* ]]; then
  SIMULATOR_LLM_PILOT_SITE_URL="https://${SIMULATOR_LLM_PILOT_SITE_URL}"
fi
export SIMULATOR_LLM_PILOT_SITE_URL

CRED_CHECK_URL="${SIMULATOR_LLM_PILOT_SITE_URL%/}/wp-json/wp/v2/users/me?context=edit"
HTTP_CODE="$(curl -sS -o /dev/null -w '%{http_code}' \
  -u "$SIMULATOR_LLM_PILOT_USERNAME:$SIMULATOR_LLM_PILOT_APP_PASSWORD" \
  "$CRED_CHECK_URL" || echo "000")"
if [[ "$HTTP_CODE" != "200" ]]; then
  echo "Error: credential check against $CRED_CHECK_URL returned $HTTP_CODE (expected 200)" >&2
  exit 1
fi
echo "Credentials OK ($HTTP_CODE)"

if [[ -n "${BUILDKITE:-}" ]]; then
  echo "--- :arrow_down: Downloading Build Artifacts"
  download_artifact "build-products-${APP}.tar"
  tar -xf "build-products-${APP}.tar"
fi

echo "--- :iphone: Setting up Simulator"
export SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17}"

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

echo "Simulator UDID: $UDID"

APP_PATH=$(find DerivedData/Build/Products -name "${APP_DISPLAY_NAME}.app" -path "*Debug-iphonesimulator*" | head -1)
if [[ -z "$APP_PATH" ]]; then
  echo "Error: ${APP_DISPLAY_NAME}.app not found in build products" >&2
  exit 1
fi
echo "Installing $APP_PATH on simulator..."
xcrun simctl install "$UDID" "$APP_PATH"

echo "--- :robot_face: Tests"
rm -f ./ai-test-status ./ai-test-results.zip

TEST_DIR="${TEST_DIR:-Tests/AgentTests/ui-tests}"
PROMPT=$(cat <<PROMPT_EOF
Use the ai-test-runner skill to run end-to-end tests.

- App: $APP_DISPLAY_NAME
- Test directory: $TEST_DIR
- Site URL: $SIMULATOR_LLM_PILOT_SITE_URL
- Username: $SIMULATOR_LLM_PILOT_USERNAME
- Application password: $SIMULATOR_LLM_PILOT_APP_PASSWORD

## CI status signal

You must write "PASS" or "FAIL" to "./ai-test-status" as the final action of the session (after the test run, or at the point of stop-and-report). CI will read this file to determine whether the tests passed or failed.

Do not write "PASS" unless every setup step succeeded and the "ai-test-runner" report shows zero failed test cases.
PROMPT_EOF
)

echo "Running tests with the following prompt:"
echo "──────────────────────────── PROMPT ────────────────────────────"
echo "$PROMPT"
echo "────────────────────────────────────────────────────────────────"

JQ_FILTER=$(cat <<'JQ_EOF'
def basename: split("/") | .[-1];
def tool_summary:
  .name + " - " +
  ( if .input.description then .input.description
    elif .name == "Skill" then (.input.skill // "?")
    elif .name == "Glob" then (.input.pattern // "?")
    elif .name == "Grep" then (.input.pattern // "?")
    elif .name == "Read" then ((.input.file_path // "?") | basename)
    elif .name == "Edit" or .name == "Write" then ((.input.file_path // "?") | basename)
    elif .name == "Agent" then (.input.description // .input.subagent_type // "?")
    else (.input | tojson | .[0:80])
    end );

fromjson? |
( if .type == "system" and .subtype == "init" then
    "── session start  model=" + (.model // "?") + " ──"
  elif .type == "assistant" then
    ( .message.content[]? |
      if .type == "thinking" then
        "(thinking) " + ((.thinking // "") | gsub("\n"; " ") | .[0:200])
      elif .type == "text" then
        (.text // "")
      elif .type == "tool_use" then
        " • " + tool_summary
      else empty end )
  elif .type == "result" then
    "── done  cost=$" + ((.total_cost_usd // 0) | tostring)
      + "  tokens=" + ((.usage.input_tokens // 0) | tostring)
      + "/" + ((.usage.output_tokens // 0) | tostring) + " ──"
  else empty end )
| select(. != null and . != "")
JQ_EOF
)

claude --bare -p \
  --model sonnet \
  --permission-mode auto \
  --output-format stream-json \
  --verbose \
  "$PROMPT" \
  | tee claude-code-session-output.txt \
  | jq -R -r --unbuffered "$JQ_FILTER"

status=$(cat ./ai-test-status 2>/dev/null || echo "missing")
if [[ "$status" != "PASS" ]]; then
  echo "AI E2E tests failed (status: $status)"
  exit 1
fi
