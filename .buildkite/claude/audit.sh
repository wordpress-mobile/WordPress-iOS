#!/bin/bash
# Sourced by claude-pr-review.sh. Records what the reviewer user does on this
# VM, from places the reviewer can't change, into $AUDIT_DIR:
#
# - hooks.jsonl: every tool call Claude makes (managed-settings hooks, so
#   Claude can't turn them off), sent to a listener run by the build user
# - es-events.jsonl.gz: Endpoint Security events (eslogger, as root) for the
#   reviewer's processes: process launches, file opens, changes and deletes
# - network.pcap / dns.pcap: the reviewer's outgoing connections (pf logs them
#   by user) and DNS traffic, to name the addresses
#
# audit-summarize.py turns these into readable lists, and audit-checks.txt
# records whether each log worked, using a known command run as the reviewer.
#
# AUDIT_DIR is set by the caller.
# shellcheck disable=SC2153

AUDIT_ES_EVENTS=(exec fork exit open close create rename unlink link truncate clone signal sudo su setuid seteuid uipc_connect)
AUDIT_MANAGED_DIR="/Library/Application Support/ClaudeCode"
AUDIT_PF_ANCHOR="com.apple/claude-review"
AUDIT_CANARY_URL="https://example.com/?claude-audit-canary"
audit_started=false

audit_note() { echo "$*" | tee -a "$AUDIT_DIR/audit-checks.txt"; }

# $1 = reviewer user ID. Everything here is best-effort: a log that doesn't
# start is reported in audit-checks.txt, and the review still runs.
audit_start() {
  AUDIT_UID="$1"
  mkdir -p "$AUDIT_DIR"
  audit_started=true
  echo "--- :mag: Starting the audit logs"

  # Hooks. The listener runs as the build user, so the reviewer can add
  # records but not change them.
  python3 -I .buildkite/claude/audit-hook-listener.py "$AUDIT_DIR/hooks.jsonl" "$AUDIT_DIR/.hook-port" \
    2> "$AUDIT_DIR/hook-listener.err" &
  AUDIT_LISTENER_PID=$!
  local port=""
  for _ in {1..50}; do
    port=$(cat "$AUDIT_DIR/.hook-port" 2>/dev/null || true)
    [[ -n "$port" ]] && break
    sleep 0.1
  done
  if [[ -n "$port" ]]; then
    local hook="/usr/bin/python3 -I '${AUDIT_MANAGED_DIR}/audit-hook.py' ${port}"
    jq -n --arg command "$hook" '
      {type: "command", command: $command, timeout: 30} as $hook
      | {
          allowManagedHooksOnly: true,
          hooks: (
            (["PreToolUse", "PostToolUse", "PostToolUseFailure"] | map({key: ., value: [{matcher: "*", hooks: [$hook]}]}))
            + (["SessionStart", "SessionEnd", "UserPromptSubmit", "SubagentStart", "SubagentStop", "Stop"] | map({key: ., value: [{hooks: [$hook]}]}))
            | from_entries)
        }' > "$AUDIT_DIR/managed-settings.json"
    if sudo -n mkdir -p "$AUDIT_MANAGED_DIR" \
      && sudo -n install -o root -g wheel -m 0644 .buildkite/claude/audit-hook.py "${AUDIT_MANAGED_DIR}/audit-hook.py" \
      && sudo -n install -o root -g wheel -m 0644 "$AUDIT_DIR/managed-settings.json" "${AUDIT_MANAGED_DIR}/managed-settings.json"; then
      audit_note "Hook log: listening on 127.0.0.1:${port}"
    else
      audit_note "Hook log: FAILED to install the managed settings"
    fi
  else
    audit_note "Hook log: FAILED to start the listener (see hook-listener.err)"
  fi

  # Endpoint Security, as root. A prefilter keeps only lines that mention the
  # reviewer's user ID; audit-summarize.py checks each event's process exactly.
  mkfifo "$AUDIT_DIR/.es-fifo"
  grep -E "\"[er]uid\" *: *${AUDIT_UID}[^0-9]" < "$AUDIT_DIR/.es-fifo" | gzip -1 > "$AUDIT_DIR/es-events.jsonl.gz" &
  AUDIT_ES_GZIP_PID=$!
  # The build user reads the output, so the redirect is meant to run without sudo.
  # shellcheck disable=SC2024
  sudo -n eslogger "${AUDIT_ES_EVENTS[@]}" > "$AUDIT_DIR/.es-fifo" 2> "$AUDIT_DIR/eslogger.err" &
  sleep 3
  if sudo -n pgrep -x eslogger > /dev/null; then
    audit_note "Endpoint Security log: running (${AUDIT_ES_EVENTS[*]})"
  else
    audit_note "Endpoint Security log: FAILED to start: $(head -c 500 "$AUDIT_DIR/eslogger.err" | tr '\n' ' ')"
  fi

  # Network. pf logs the first packet of each connection the reviewer makes
  # (localhost excluded) to pflog0. Nothing is blocked.
  if ! sudo -n pfctl -s rules 2>/dev/null | grep -qF 'anchor "com.apple/*"'; then
    sudo -n pfctl -f /etc/pf.conf > /dev/null 2>&1 || true
  fi
  AUDIT_PF_TOKEN=$(sudo -n pfctl -E 2>&1 | awk '/Token/ {print $NF}' || true)
  sudo -n ifconfig pflog0 create > /dev/null 2>&1 || true
  if printf 'pass out log quick on ! lo0 proto { tcp, udp } from any to any user = %s keep state\n' "$AUDIT_UID" \
      | sudo -n pfctl -a "$AUDIT_PF_ANCHOR" -f - 2> "$AUDIT_DIR/pf.err"; then
    # shellcheck disable=SC2024
    sudo -n pfctl -a "$AUDIT_PF_ANCHOR" -s rules > "$AUDIT_DIR/pf-rules.txt" 2>&1 || true
    sudo -n tcpdump -n -U -i pflog0 -w "$AUDIT_DIR/network.pcap" 2> "$AUDIT_DIR/tcpdump-network.err" &
    local interface
    interface=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}' || true)
    sudo -n tcpdump -n -U -i "${interface:-en0}" -w "$AUDIT_DIR/dns.pcap" 'port 53' 2> "$AUDIT_DIR/tcpdump-dns.err" &
    sleep 1
    audit_note "Network log: pf rule loaded; DNS on ${interface:-en0}"
  else
    audit_note "Network log: FAILED to load the pf rule: $(head -c 500 "$AUDIT_DIR/pf.err" | tr '\n' ' ')"
  fi
}

# Runs a known command as the reviewer, so audit_stop can check that each log
# recorded it. Needs as_reviewer from claude-pr-review.sh.
audit_canary() {
  as_reviewer "curl -sS -o /dev/null --max-time 20 '${AUDIT_CANARY_URL}'; head -c 1 /etc/hosts > /dev/null" || true
}

audit_stop() {
  [[ "$audit_started" == true ]] || return 0
  audit_started=false
  echo "--- :mag: Collecting the audit logs"

  sudo -n pkill -INT -x eslogger > /dev/null 2>&1 || true
  if [[ -n "${AUDIT_ES_GZIP_PID:-}" ]]; then wait "$AUDIT_ES_GZIP_PID" || true; fi
  sudo -n pkill -INT -x tcpdump > /dev/null 2>&1 || true
  sleep 1
  sudo -n pfctl -a "$AUDIT_PF_ANCHOR" -F all > /dev/null 2>&1 || true
  if [[ -n "${AUDIT_PF_TOKEN:-}" ]]; then sudo -n pfctl -X "$AUDIT_PF_TOKEN" > /dev/null 2>&1 || true; fi
  kill "${AUDIT_LISTENER_PID:-}" 2>/dev/null || true
  sudo -n chown -R "$(id -un)" "$AUDIT_DIR" || true
  rm -f "$AUDIT_DIR/.es-fifo" "$AUDIT_DIR/.hook-port"

  tcpdump -n -e -tttt -r "$AUDIT_DIR/network.pcap" > "$AUDIT_DIR/network.txt" 2>/dev/null || true
  tcpdump -n -tttt -r "$AUDIT_DIR/dns.pcap" > "$AUDIT_DIR/dns.txt" 2>/dev/null || true
  python3 -I .buildkite/claude/audit-summarize.py "$AUDIT_DIR" "$AUDIT_UID" \
    || audit_note "Summary: FAILED"

  # Did each log record the canary?
  found() { [[ -f "$AUDIT_DIR/$1" ]] && grep -qF -- "$2" "$AUDIT_DIR/$1"; }
  if found processes.txt claude-audit-canary; then audit_note "Check: the canary's curl is in processes.txt"; else audit_note "Check: MISSING the canary's curl in processes.txt"; fi
  if found files-read.txt etc/hosts; then audit_note "Check: the canary's read of /etc/hosts is in files-read.txt"; else audit_note "Check: MISSING the canary's read of /etc/hosts in files-read.txt"; fi
  if found network-summary.txt example.com; then audit_note "Check: the canary's connection to example.com is in network-summary.txt"; else audit_note "Check: MISSING the canary's connection to example.com in network-summary.txt"; fi

  # Every tool call should be in both the hook log and the transcript.
  local hook_calls transcript_calls
  hook_calls=$(jq -s '[.[] | select(.record.hook_event_name? == "PreToolUse")] | length' "$AUDIT_DIR/hooks.jsonl" 2>/dev/null || echo "?")
  transcript_calls=$(jq -s '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")] | length' "$AUDIT_DIR/transcript.jsonl" 2>/dev/null || echo "?")
  audit_note "Check: ${hook_calls} tool call(s) in hooks.jsonl, ${transcript_calls} in transcript.jsonl"
  for file in event-counts.txt network-summary.txt; do
    [[ -s "$AUDIT_DIR/$file" ]] && { echo "${file}:"; head -n 30 "$AUDIT_DIR/$file"; }
  done
  return 0
}
