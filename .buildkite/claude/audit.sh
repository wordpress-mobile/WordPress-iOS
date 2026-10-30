#!/bin/bash
# Sourced by claude-pr-review.sh. Records what the reviewer user does on this
# VM, from places the reviewer can't change:
#
# - Hooks: every tool call Claude makes (managed-settings hooks, so Claude
#   can't turn them off), sent to a listener run by the build user.
# - Endpoint Security (eslogger, as root): the reviewer's process launches,
#   file opens, changes and deletes, filtered by audit-es-filter.py.
# - Network: the reviewer's outgoing connections (pf logs them by user) and
#   DNS traffic, to name the addresses.
# - Claude's transcript ($TRANSCRIPT_FILE, append-only).
#
# The logs are uploaded in parts while the review runs (every
# $AUDIT_UPLOAD_SECONDS), to build/claude-audit-live/, because a cancelled or
# timed-out job loses everything still on the VM. Rebuild a log by joining its
# parts in order, e.g. `cat es-events.*.jsonl.gz > es-events.jsonl.gz` or
# `mergecap -w network.pcap network-*.pcap`.
#
# At the end, audit-summarize.py turns the parts into readable lists in
# $AUDIT_DIR, and audit-checks.txt records whether each log worked, using a
# known command run as the reviewer. Everything is then packed into
# $AUDIT_ARCHIVE. Every file is checked for this job's secrets before it's
# uploaded.
#
# AUDIT_DIR and TRANSCRIPT_FILE are set by the caller.
# shellcheck disable=SC2153

AUDIT_ES_EVENTS=(exec fork exit open close create rename unlink link truncate clone signal sudo su setuid seteuid uipc_connect)
AUDIT_MANAGED_DIR="/Library/Application Support/ClaudeCode"
AUDIT_PF_ANCHOR="com.apple/claude-review"
AUDIT_CANARY_URL="https://example.com/?claude-audit-canary"
AUDIT_RAW="build/claude-audit-raw"
AUDIT_LIVE="build/claude-audit-live"
AUDIT_UPLOAD_SECONDS=120
AUDIT_ARCHIVE="build/audit-log.tar.gz"
audit_started=false

audit_note() { echo "$*" | tee -a "$AUDIT_DIR/audit-checks.txt"; }

# Stops processes by name: SIGINT so they can flush their output, then SIGTERM,
# then SIGKILL, each after $2 seconds. Prints the signal that stopped them.
audit_stop_process() {
  local signal
  sudo -n pgrep -x "$1" > /dev/null 2>&1 || { echo "not running"; return 0; }
  for signal in INT TERM KILL; do
    sudo -n pkill "-${signal}" -x "$1" > /dev/null 2>&1 || true
    for _ in $(seq 1 "$2"); do
      sudo -n pgrep -x "$1" > /dev/null 2>&1 || { echo "SIG${signal}"; return 0; }
      sleep 1
    done
  done
  echo "still running"
}

# Exits 0 if the file contains one of this job's secrets. The values are passed
# to grep on a file descriptor, never as arguments, so other users can't see
# them with `ps`.
audit_has_secret() {
  [[ -n "$AUDIT_SECRETS" ]] || return 1
  if [[ "$1" == *.gz ]]; then
    # grep -q stops at the first match, so gzip gets SIGPIPE. Under pipefail
    # that would turn a match into "no secret", so gzip's status is ignored.
    { gzip -dc "$1" 2>/dev/null || true; } | grep -q -a -F -f <(printf '%s\n' "$AUDIT_SECRETS")
  else
    grep -q -a -F -f <(printf '%s\n' "$AUDIT_SECRETS") "$1" 2>/dev/null
  fi
}

# Uploads one part as a Buildkite artifact, unless it contains a secret.
audit_upload_part() {
  if audit_has_secret "$1"; then
    rm -f "$1"
    audit_note "REMOVED ${1}: it contained one of this job's secrets"
    return 0
  fi
  buildkite-agent artifact upload "$1" > /dev/null 2>> "$AUDIT_RAW/upload.err" \
    || echo "Warning: could not upload ${1} (see upload.err)."
}

# Moves finished parts of every log into $AUDIT_LIVE and uploads them. With
# $1 = final, also takes the parts still being written.
audit_flush() {
  local final="${1:-}" file kind newest count=0 name
  # Endpoint Security: audit-es-filter.py renames each part when it's finished.
  while IFS= read -r -d '' file; do
    mv "$file" "$AUDIT_LIVE/es/" && audit_upload_part "$AUDIT_LIVE/es/${file##*/}" && count=$((count + 1))
  done < <(find "$AUDIT_RAW/es" -name 'es-events.*.jsonl.gz' -print0 2>/dev/null)
  # Network: tcpdump starts a new file every $AUDIT_UPLOAD_SECONDS; the newest is still open.
  for kind in network dns; do
    newest=$(find "$AUDIT_RAW/$kind" -name '*.pcap' 2>/dev/null | sort | tail -n 1)
    while IFS= read -r file; do
      [[ -n "$file" ]] || continue
      [[ "$final" == final || "$file" != "$newest" ]] || continue
      mv "$file" "$AUDIT_LIVE/$kind/" && audit_upload_part "$AUDIT_LIVE/$kind/${file##*/}" && count=$((count + 1))
    done < <(find "$AUDIT_RAW/$kind" -name '*.pcap' 2>/dev/null | sort)
  done
  # Hooks and transcript: the lines added since the last part.
  for name in hooks transcript; do
    if [[ "$name" == hooks ]]; then file="$AUDIT_RAW/hooks.jsonl"; else file="$TRANSCRIPT_FILE"; fi
    local number part
    number=$(( $(cat "$AUDIT_RAW/.parts-$name" 2>/dev/null || echo 0) + 1 ))
    part="$AUDIT_LIVE/$name/$name.$(printf '%05d' "$number").jsonl"
    if python3 -I .buildkite/claude/audit-cut.py ${final:+--all} "$file" "$AUDIT_RAW/.offset-$name" "$part"; then
      echo "$number" > "$AUDIT_RAW/.parts-$name"
      audit_upload_part "$part" && count=$((count + 1))
    fi
  done
  if [[ "$count" -gt 0 ]]; then echo "Uploaded ${count} audit log part(s)."; fi
}

# $1 = reviewer user ID, $2 = reviewer home. Everything here is best-effort: a
# log that doesn't start is reported in audit-checks.txt, and the review still runs.
audit_start() {
  AUDIT_UID="$1"
  local reviewer_home="$2"
  mkdir -p "$AUDIT_DIR" "$AUDIT_RAW"/{es,network,dns} "$AUDIT_LIVE"/{es,network,dns,hooks,transcript}
  # The rest of the checkout is world-readable; the audit logs shouldn't be.
  chmod 0700 "$AUDIT_DIR" "$AUDIT_RAW" "$AUDIT_LIVE"
  AUDIT_SECRETS=$(for var in ANTHROPIC_API_KEY GITHUB_TOKEN GH_TOKEN SPACEFAST_TOKEN BUILDKITE_AGENT_ACCESS_TOKEN AWS_SECRET_ACCESS_KEY; do
    [[ -n "${!var:-}" ]] && printf '%s\n' "${!var}"
  done)
  audit_started=true
  echo "--- :mag: Starting the audit logs"

  # Hooks. The listener runs as the build user, so the reviewer can add
  # records but not change them.
  python3 -I .buildkite/claude/audit-hook-listener.py "$AUDIT_RAW/hooks.jsonl" "$AUDIT_RAW/.hook-port" \
    2> "$AUDIT_DIR/hook-listener.err" &
  AUDIT_LISTENER_PID=$!
  local port=""
  for _ in {1..50}; do
    port=$(cat "$AUDIT_RAW/.hook-port" 2>/dev/null || true)
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

  # Endpoint Security, as root. grep cheaply keeps only lines that mention the
  # reviewer's user ID; audit-es-filter.py checks each event exactly, removes
  # environments, redacts this job's secrets (passed on fd 3) and drops the
# noise (see that file).
  mkfifo "$AUDIT_RAW/.es-fifo"
  grep -E "\"[er]uid\" *: *${AUDIT_UID}[^0-9]" < "$AUDIT_RAW/.es-fifo" \
    | python3 -I .buildkite/claude/audit-es-filter.py "$AUDIT_UID" "$reviewer_home" "$AUDIT_RAW/es" "$AUDIT_UPLOAD_SECONDS" \
      2> "$AUDIT_DIR/es-filter.err" 3< <(printf '%s\n' "$AUDIT_SECRETS") &
  AUDIT_ES_FILTER_PID=$!
  # The build user reads the output, so the redirect is meant to run without sudo.
  # shellcheck disable=SC2024
  sudo -n eslogger "${AUDIT_ES_EVENTS[@]}" > "$AUDIT_RAW/.es-fifo" 2> "$AUDIT_DIR/eslogger.err" &
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
    sudo -n tcpdump -n -U -i pflog0 -G "$AUDIT_UPLOAD_SECONDS" -w "$AUDIT_RAW/network/network-%Y%m%d-%H%M%S.pcap" \
      2> "$AUDIT_DIR/tcpdump-network.err" &
    local interface
    interface=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}' || true)
    sudo -n tcpdump -n -U -i "${interface:-en0}" -G "$AUDIT_UPLOAD_SECONDS" -w "$AUDIT_RAW/dns/dns-%Y%m%d-%H%M%S.pcap" 'port 53' \
      2> "$AUDIT_DIR/tcpdump-dns.err" &
    sleep 1
    audit_note "Network log: pf rule loaded; DNS on ${interface:-en0}"
  else
    audit_note "Network log: FAILED to load the pf rule: $(head -c 500 "$AUDIT_DIR/pf.err" | tr '\n' ' ')"
  fi

  # Uploads parts until audit_stop creates the stop file.
  (
    elapsed=0
    while [[ ! -e "$AUDIT_RAW/.stop" ]]; do
      sleep 5
      elapsed=$((elapsed + 5))
      if [[ "$elapsed" -ge "$AUDIT_UPLOAD_SECONDS" ]]; then
        elapsed=0
        audit_flush || true
      fi
    done
  ) &
  AUDIT_UPLOADER_PID=$!
  audit_note "Audit logs are uploaded in parts every ${AUDIT_UPLOAD_SECONDS}s to ${AUDIT_LIVE}/"
}

# Runs a known command as the reviewer, so audit_stop can check that each log
# recorded it. Needs as_reviewer from claude-pr-review.sh.
audit_canary() {
  as_reviewer "curl -sS -o /dev/null --max-time 20 '${AUDIT_CANARY_URL}'; head -c 1 /etc/hosts > /dev/null" || true
}

# Last line of defence for everything uploaded at the end of the job: removes
# any file in the given folders that contains one of this job's secrets.
audit_remove_secrets() {
  local file
  while IFS= read -r -d '' file; do
    if audit_has_secret "$file"; then
      rm -f "$file"
      audit_note "REMOVED ${file}: it contained one of this job's secrets"
    fi
  done < <(find "$@" -type f -print0)
}

# Packs every audit result, and the parts uploaded during the run, into
# $AUDIT_ARCHIVE: the one artifact to download for an audit. Runs last (from
# the EXIT trap), after the steps that post the review have added their logs.
audit_archive() {
  [[ -d "$AUDIT_DIR" ]] || return 0
  audit_remove_secrets "$AUDIT_DIR"
  if tar -czf "$AUDIT_ARCHIVE" -C "$(dirname "$AUDIT_DIR")" "$(basename "$AUDIT_DIR")" "$(basename "$AUDIT_LIVE")"; then
    echo "Audit log: ${AUDIT_ARCHIVE} ($(du -h "$AUDIT_ARCHIVE" | cut -f1))"
  else
    echo "Warning: could not create ${AUDIT_ARCHIVE}."
  fi
}

audit_stop() {
  [[ "$audit_started" == true ]] || return 0
  audit_started=false
  echo "--- :mag: Collecting the audit logs"

  local started=$SECONDS
  audit_note "Endpoint Security log: stopped with $(audit_stop_process eslogger 5)"
  for _ in $(seq 1 60); do kill -0 "${AUDIT_ES_FILTER_PID:-}" 2>/dev/null || break; sleep 1; done
  if kill -0 "${AUDIT_ES_FILTER_PID:-}" 2>/dev/null; then
    audit_note "Warning: the Endpoint Security filter was still running after 60 seconds."
  fi
  audit_note "Network log: stopped with $(audit_stop_process tcpdump 5)"
  sudo -n pfctl -a "$AUDIT_PF_ANCHOR" -F all > /dev/null 2>&1 || true
  if [[ -n "${AUDIT_PF_TOKEN:-}" ]]; then sudo -n pfctl -X "$AUDIT_PF_TOKEN" > /dev/null 2>&1 || true; fi
  kill "${AUDIT_LISTENER_PID:-}" 2>/dev/null || true

  # Let the uploader finish its current round, then upload what's left.
  touch "$AUDIT_RAW/.stop"
  for _ in $(seq 1 120); do kill -0 "${AUDIT_UPLOADER_PID:-}" 2>/dev/null || break; sleep 1; done
  kill "${AUDIT_UPLOADER_PID:-}" 2>/dev/null || true
  sudo -n chown -R "$(id -un)" "$AUDIT_RAW" "$AUDIT_DIR" || true
  audit_flush final
  cp "$AUDIT_RAW/hooks.jsonl" "$AUDIT_DIR/hooks.jsonl" 2>/dev/null || true
  cp "$AUDIT_RAW/es/es-dropped.json" "$AUDIT_DIR/es-dropped.json" 2>/dev/null || true
  echo "Logs stopped in $((SECONDS - started))s. Parts uploaded:"
  du -sh "$AUDIT_LIVE"/* 2>/dev/null | sed 's/^/  /'

  started=$SECONDS
  local file
  : > "$AUDIT_DIR/network.txt"
  : > "$AUDIT_DIR/dns.txt"
  for file in "$AUDIT_LIVE"/network/*.pcap; do tcpdump -n -e -tttt -r "$file" >> "$AUDIT_DIR/network.txt" 2>/dev/null || true; done
  for file in "$AUDIT_LIVE"/dns/*.pcap; do tcpdump -n -tttt -r "$file" >> "$AUDIT_DIR/dns.txt" 2>/dev/null || true; done
  python3 -I .buildkite/claude/audit-summarize.py "$AUDIT_DIR" "$AUDIT_UID" "$AUDIT_LIVE/es" \
    || audit_note "Summary: FAILED"
  echo "Summarized in $((SECONDS - started))s."

  audit_remove_secrets "$AUDIT_DIR" "${EVIDENCE_DIR:-$AUDIT_DIR}"

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

  # Lists of paths compress well. Small files stay readable in Buildkite.
  while IFS= read -r -d '' file; do
    gzip -9 "$file" || true
  done < <(find "$AUDIT_DIR" -type f \( -name '*.txt' -o -name '*.jsonl' \) -size +1M -print0)
  return 0
}
