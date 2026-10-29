#!/bin/bash

# Checks, end to end, that the Claude PR review setup can test real PRs. Runs
# as the `claude-reviewer` user from claude-pr-review-as-reviewer.sh, before
# Claude, when CLAUDE_REVIEW_VALIDATE_SETUP is `true`.
#
#   1. Build the Jetpack app for the simulator, the way Claude would.
#   2. Install and launch it with a test site's credentials.
#   3. Sign in by tapping through with AXe, taking a screenshot of each step.
#   4. Confirm the sign-in from the screen and from the site's access log.
#   5. Build and run one unit test from the WordPress test plan.
#
# Usage: validate-setup.sh <simulator UDID> <evidence dir> <report file>
#
# Each step's result is a line in the report. A failed step doesn't stop the
# others, and the script always exits 0: Claude still reviews either way.

set -uo pipefail

UDID="$1"
EVIDENCE="$2"
REPORT="$3"
SITE="ci-check"
BUNDLE_ID="com.automattic.jetpack"
APP="DerivedData/Build/Products/Debug-iphonesimulator/Jetpack.app"
SHOTS="$EVIDENCE/validate"

mkdir -p "$SHOTS"
result() { echo "Validate: $*" | tee -a "$REPORT"; }
shot() { xcrun simctl io "$UDID" screenshot "$SHOTS/$1.png" > /dev/null 2>&1 || true; }
ui() { axe describe-ui --udid "$UDID" 2> /dev/null > "$SHOTS/$1.json" || true; }
seconds_since() { echo "$(($(date +%s) - $1))s"; }

# ── 1. Build ─────────────────────────────────────────────────────────
echo "--- :hammer_and_wrench: Validate: building Jetpack as $(id -un)"
start=$(date +%s)
if xcodebuild -quiet -workspace WordPress.xcworkspace -scheme Jetpack -destination "id=$UDID" \
  -derivedDataPath DerivedData build > "$EVIDENCE/validate-build.log" 2>&1 && [ -d "$APP" ]; then
  result "Jetpack build works ($(seconds_since "$start"))"
else
  result "Jetpack build FAILED after $(seconds_since "$start") (see validate-build.log)"
  tail -n 40 "$EVIDENCE/validate-build.log"
  exit 0
fi

# ── 2. Install and launch with the test site's credentials ───────────
echo "--- :iphone: Validate: signing in to a test site"
if ! site=$(.buildkite/claude/wp-test-site.sh info "$SITE" 2> /dev/null); then
  result "sign-in SKIPPED: the '$SITE' test site wasn't created"
else
  site_url=$(jq -r .url <<< "$site")
  site_dir=$(dirname "$(jq -r .path <<< "$site")")
  access_log="$site_dir/httpd-access.log"
  log_lines_before=$(wc -l < "$access_log" 2> /dev/null || echo 0)

  xcrun simctl install "$UDID" "$APP"
  xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" \
    -ui-test-site-url "$site_url" \
    -ui-test-site-user "$(jq -r .username <<< "$site")" \
    -ui-test-site-pass "$(jq -r .application_password <<< "$site")" > /dev/null

  # ── 3. Tap through the sign-in screen (docs/simulator-sign-in.md) ──
  tapped=yes
  sleep 5
  shot 1-launched
  ui 1-launched
  axe tap --label "Enter your existing site address" --wait-timeout 60 --udid "$UDID" > /dev/null 2>&1 || tapped=no
  shot 2-site-address
  ui 2-site-address
  if [ "$tapped" = yes ]; then
    axe tap --id "Site address" --wait-timeout 20 --udid "$UDID" > /dev/null 2>&1 || tapped=no
    axe type "$site_url" --udid "$UDID" > /dev/null 2>&1 || tapped=no
    shot 3-typed-address
    axe tap --id "Site Address Next Button" --wait-timeout 20 --udid "$UDID" > /dev/null 2>&1 || tapped=no
  fi
  sleep 20
  shot 4-after-continue
  ui 4-after-continue

  if [ "$tapped" = yes ]; then
    result "AXe tapped through the sign-in screen"
  else
    result "AXe could NOT tap through the sign-in screen (see validate/*.png and *.json)"
  fi

  # ── 4. Confirm the sign-in ───────────────────────────────────────
  # The app only calls these with the application password once it's signed in.
  new_requests=$(tail -n +"$((log_lines_before + 1))" "$access_log" 2> /dev/null || true)
  echo "$new_requests" > "$EVIDENCE/validate-site-requests.log"
  # Matches both /wp-json/wp/v2/... and ?rest_route=/wp/v2/... (plain or URL-encoded).
  authenticated=$(grep -c -E '"(GET|POST) [^"]*(/wp/v2/|%2Fwp%2Fv2%2F)(users(/|%2F)me|posts|settings)[^"]*" 200 ' <<< "$new_requests" || true)
  if [ "${authenticated:-0}" -gt 0 ]; then
    result "the app signed in to ${site_url}: ${authenticated} authenticated REST request(s) answered 200"
  else
    total=$(grep -c . <<< "$new_requests" || true)
    result "sign-in NOT confirmed: ${total:-0} request(s) reached the site, none an authenticated REST call (see validate-site-requests.log)"
  fi
fi

# ── 5. Build and run one unit test ───────────────────────────────────
echo "--- :test_tube: Validate: running one unit test as $(id -un)"
start=$(date +%s)
if xcodebuild -quiet -workspace WordPress.xcworkspace -scheme WordPress -testPlan WordPressUnitTests \
  -destination "id=$UDID" -derivedDataPath DerivedData \
  -only-testing:WordPressSharedTests/EmailFormatValidatorTests test > "$EVIDENCE/validate-test.log" 2>&1; then
  result "unit tests build and run ($(seconds_since "$start"))"
else
  result "unit test run FAILED after $(seconds_since "$start") (see validate-test.log)"
  tail -n 40 "$EVIDENCE/validate-test.log"
fi

exit 0
