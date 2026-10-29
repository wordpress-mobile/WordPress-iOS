#!/bin/bash
# Runs as the unprivileged `claude-reviewer` user, started by claude-pr-review.sh.
# Checks that this user can't reach the build user's secrets, then runs Claude.
#
# Exit status: 0 = Claude ran (the verdict is in the transcript), 3 = an
# isolation check failed and Claude did not run, anything else = an error.

set -euo pipefail

AXE_VERSION="1.8.0"
AXE_SHA256="7b76340b72e90d0f211bc7c4636f15009076eff07acef2f2b632b175debd8834"

# shellcheck source=/dev/null
source "$HOME/review.env"
cd "$HOME/wordpress-ios"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
mkdir -p "$EVIDENCE_DIR"
report="$EVIDENCE_DIR/isolation-checks.txt"
: > "$report"

# ── Isolation checks ─────────────────────────────────────────────────
# Prints only file names and variable names, never contents or values.
echo "--- :lock: Isolation checks as $(id -un)"
leaks=0
check() {  # $1 = OK|LEAK, $2 = description
  echo "$1 $2" | tee -a "$report"
  if [[ "$1" == LEAK ]]; then leaks=$((leaks + 1)); fi
}

# Folders where the build user's secrets live. Seeing a folder's file names is
# fine; being able to read any file inside it is not.
for dir in \
  "$BUILDER_HOME/.aws" \
  "$BUILDER_HOME/.ssh" \
  "$BUILDER_HOME/.config" \
  "$BUILDER_HOME/Library/Keychains" \
  "/Volumes/My Shared Files/common-credentials"; do
  if [[ ! -e "$dir" ]] && ! ls -d "$dir" >/dev/null 2>&1; then
    check OK "can't see ${dir}"
    continue
  fi
  readable=$(find "$dir" -maxdepth 3 -type f 2>/dev/null | while IFS= read -r file; do
      if head -c 1 "$file" >/dev/null 2>&1; then echo "${file#"$dir"/}"; fi
    done | head -n 20 | tr '\n' ' ' || true)
  if [[ -n "$readable" ]]; then
    check LEAK "can read files in ${dir}: ${readable}"
  else
    check OK "can't read any file in ${dir}"
  fi
done
if [[ -f "$BUILDER_HOME/.netrc" ]] && head -c 1 "$BUILDER_HOME/.netrc" >/dev/null 2>&1; then
  check LEAK "can read ${BUILDER_HOME}/.netrc"
fi

secret_vars='BUILDKITE_AGENT_ACCESS_TOKEN|AWS_SECRET_ACCESS_KEY|AWS_ACCESS_KEY_ID|GITHUB_TOKEN|GH_TOKEN|ANTHROPIC_API_KEY|SPACEFAST_TOKEN'
env_leaks=0
for pid in $(pgrep -u "$BUILDER_USER" || true); do
  names=$(ps -E -ww -o command= -p "$pid" 2>/dev/null | grep -o -E "(^| )(${secret_vars})=" | tr -d ' ' | sort -u | tr '\n' ' ' || true)
  if [[ -n "$names" ]]; then
    check LEAK "can read ${names}in the environment of ${BUILDER_USER} pid ${pid} ($(ps -o comm= -p "$pid" 2>/dev/null | xargs basename 2>/dev/null))"
    env_leaks=1
  fi
done
if [[ "$env_leaks" == 0 ]]; then check OK "can't read secrets in any ${BUILDER_USER} process environment"; fi

if kill -0 "$BUILDER_PID" 2>/dev/null; then check LEAK "can signal ${BUILDER_USER} pid ${BUILDER_PID}"; else check OK "can't signal ${BUILDER_USER} processes"; fi
if sudo -n true 2>/dev/null; then check LEAK "can use sudo"; else check OK "can't use sudo"; fi
if dseditgroup -o checkmember -m "$(id -un)" admin >/dev/null 2>&1; then check LEAK "is in the admin group"; else check OK "is not in the admin group"; fi

if [[ "$leaks" -gt 0 ]]; then
  echo "^^^ +++ ${leaks} isolation check(s) failed, so Claude will not run."
  exit 3
fi

# ── Capability checks (informational) ────────────────────────────────
mkdir -p "$HOME/.local/bin"
echo "--- :claude: Installing Claude Code ${CLAUDE_CODE_VERSION}"
curl -fsSL https://claude.ai/install.sh | bash -s "$CLAUDE_CODE_VERSION" > /dev/null
claude --version

echo "--- :iphone: Simulator as $(id -un)"
SIMULATOR_UDID=$(xcrun simctl list devices available -j \
  | python3 -c 'import json,sys; n=sys.argv[1]; print(next((d["udid"] for r in json.load(sys.stdin)["devices"].values() for d in r if d["name"]==n), ""))' "$SIMULATOR_NAME")
if [[ -z "$SIMULATOR_UDID" ]]; then
  SIMULATOR_UDID=$(xcrun simctl create "$SIMULATOR_NAME" "$SIMULATOR_NAME")
fi
xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$SIMULATOR_UDID" -b > /dev/null
echo "Booted ${SIMULATOR_NAME}: ${SIMULATOR_UDID}" | tee -a "$report"
if xcrun simctl io "$SIMULATOR_UDID" screenshot "$EVIDENCE_DIR/isolation-simulator.png" > /dev/null 2>&1; then
  echo "Simulator screenshot: works" | tee -a "$report"
else
  echo "Simulator screenshot: FAILED" | tee -a "$report"
fi

echo "--- :point_up_2: AXe ${AXE_VERSION} for tapping in the simulator"
# AXe drives the simulator directly (taps, typing, swipes, the accessibility
# tree), without Xcode MCP or WebDriverAgent. Installed into this user's home.
axe_dir="$HOME/.local/axe"
axe_tar="$(mktemp)"
# Best-effort: if the download fails, Claude still runs without AXe.
if curl -fsSL -o "$axe_tar" "https://github.com/cameroncooke/AXe/releases/download/v${AXE_VERSION}/AXe-macOS-v${AXE_VERSION}-universal.tar.gz" \
  && echo "${AXE_SHA256}  ${axe_tar}" | shasum -a 256 -c - > /dev/null; then
  mkdir -p "$axe_dir"
  tar -xzf "$axe_tar" -C "$axe_dir"
  # On PATH as a folder, not a symlink: axe loads the frameworks next to it.
  export PATH="$axe_dir:$PATH"
  # The first call can fail while the simulator finishes starting, so try a few times.
  axe_status="FAILED (see axe-check.log)"
  for attempt in 1 2 3; do
    if axe describe-ui --udid "$SIMULATOR_UDID" > /dev/null 2>> "$EVIDENCE_DIR/axe-check.log"; then
      axe_status="works (attempt ${attempt})"
      break
    fi
    sleep 10
  done
  echo "AXe: ${axe_status}" | tee -a "$report"
else
  echo "AXe: download FAILED" | tee -a "$report"
fi
rm -f "$axe_tar"

echo "--- :wordpress: Test site check"
# Creates one site the way Claude would, and checks the REST API accepts its
# application password. Only the URL and timing are logged.
site_start=$(date +%s)
if site_json=$(.buildkite/claude/wp-test-site.sh start ci-check 2> "$EVIDENCE_DIR/wp-test-site-check.log"); then
  site_url=$(jq -r .url <<<"$site_json")
  auth=$(jq -r '"\(.username):\(.application_password)"' <<<"$site_json")
  if curl -fsS -u "$auth" "${site_url}/wp-json/wp/v2/users/me" > /dev/null 2>> "$EVIDENCE_DIR/wp-test-site-check.log"; then
    echo "Test site: works (${site_url}, created in $(( $(date +%s) - site_start ))s)" | tee -a "$report"
  else
    echo "Test site: created at ${site_url}, but the REST API rejected its application password" | tee -a "$report"
  fi
else
  echo "Test site: FAILED (see wp-test-site-check.log)" | tee -a "$report"
fi

if [[ "${CLAUDE_REVIEW_VALIDATE_SETUP:-false}" == true ]]; then
  bash .buildkite/claude/validate-setup.sh "$SIMULATOR_UDID" "$EVIDENCE_DIR" "$report"
fi

# ── Review ───────────────────────────────────────────────────────────
sed -i '' -e "s/{{SIMULATOR_UDID}}/${SIMULATOR_UDID}/g" "$HOME/prompt.md"

claude_env=("HOME=$HOME" "PATH=$PATH" "USER=$(id -un)" "LOGNAME=$(id -un)" "TMPDIR=${TMPDIR:-/tmp}"
  "LANG=en_US.UTF-8" "CI=true" "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY")
echo "--- :claude: Reviewing as $(id -un)"
env -i "${claude_env[@]}" claude -p "$(cat "$HOME/prompt.md")" \
  --model "$CLAUDE_MODEL" --effort "$CLAUDE_EFFORT" \
  --dangerously-skip-permissions \
  --strict-mcp-config \
  --json-schema "$(cat "$HOME/schema.json")" \
  --output-format stream-json --verbose \
  < /dev/null > "$EVIDENCE_DIR/transcript.jsonl" || true
