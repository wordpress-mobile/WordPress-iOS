#!/bin/bash
# Runs as the unprivileged `claude-reviewer` user, started by claude-pr-review.sh.
# Checks that this user can't reach the build user's secrets, then runs Claude.
#
# Exit status: 0 = Claude ran (the verdict is in the transcript), 3 = an
# isolation check failed and Claude did not run, anything else = an error.

set -euo pipefail

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

echo "--- :xcode: Xcode MCP as $(id -un)"
mcp_status=$(xcrun mcp-server status 2>&1 || true)
echo "$mcp_status" | sed 's/^/  /' | tee -a "$report"
# The permission alone isn't enough: the bridge must also be able to launch
# Xcode Service, which needs a desktop session. So ask it to start for real.
XCODE_MCP=no
if grep -q "unsafe-always-allow-all-agents" <<<"$mcp_status"; then
  probe=$(python3 - <<'PY' 2>&1 || true
import json, subprocess, threading
request = {"jsonrpc": "2.0", "id": 1, "method": "initialize",
           "params": {"protocolVersion": "2025-06-18", "capabilities": {},
                      "clientInfo": {"name": "ci-probe", "version": "1"}}}
proc = subprocess.Popen(["xcrun", "mcpbridge"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE, text=True)
proc.stdin.write(json.dumps(request) + "\n")
proc.stdin.flush()
reply = []
reader = threading.Thread(target=lambda: reply.append(proc.stdout.readline()), daemon=True)
reader.start()
reader.join(60)
proc.kill()
line = reply[0] if reply else ""
if '"result"' in line:
    print("ok")
else:
    err = proc.stderr.read() if proc.poll() is not None else ""
    print("failed: " + ((line or err).strip()[:300] or "no reply in 60 s"))
PY
)
  echo "Xcode MCP bridge: ${probe}" | tee -a "$report"
  if [[ "$probe" == ok ]]; then XCODE_MCP=yes; fi
fi
echo "Xcode MCP usable: ${XCODE_MCP}" | tee -a "$report"

# ── Review ───────────────────────────────────────────────────────────
sed -i '' -e "s/{{SIMULATOR_UDID}}/${SIMULATOR_UDID}/g" \
  -e "s|{{XCODE_TOOLS}}|$([[ "$XCODE_MCP" == yes ]] && echo "$XCODE_TOOLS_YES" || echo "$XCODE_TOOLS_NO")|g" "$HOME/prompt.md"

claude_env=("HOME=$HOME" "PATH=$PATH" "USER=$(id -un)" "LOGNAME=$(id -un)" "TMPDIR=${TMPDIR:-/tmp}"
  "LANG=en_US.UTF-8" "CI=true" "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY")
for var in SIMULATOR_LLM_PILOT_SITE_URL SIMULATOR_LLM_PILOT_USERNAME SIMULATOR_LLM_PILOT_APP_PASSWORD; do
  if [[ -n "${!var:-}" ]]; then claude_env+=("$var=${!var}"); fi
done
mcp_args=()
if [[ "$XCODE_MCP" == yes ]]; then
  mcp_args=(--strict-mcp-config --mcp-config '{"mcpServers": {"xcode": {"type": "stdio", "command": "xcrun", "args": ["mcpbridge"]}}}')
else
  mcp_args=(--strict-mcp-config)
fi

echo "--- :claude: Reviewing as $(id -un)"
env -i "${claude_env[@]}" claude -p "$(cat "$HOME/prompt.md")" \
  --model "$CLAUDE_MODEL" --effort "$CLAUDE_EFFORT" \
  --dangerously-skip-permissions \
  "${mcp_args[@]}" \
  --json-schema "$(cat "$HOME/schema.json")" \
  --output-format stream-json --verbose \
  < /dev/null > "$EVIDENCE_DIR/transcript.jsonl" || true
