"""Filters eslogger's output for the Claude PR review audit log.

Reads eslogger JSON lines on stdin (already narrowed by grep to lines that
mention the reviewer's user ID) and writes the reviewer's events to gzip
parts, starting a new part every <rotate seconds>. Each finished part is
renamed to es-events.<n>.jsonl.gz, so the uploader only ever sees whole parts.

To keep the log useful and safe:
- `exec` events lose their environment, which holds the Anthropic key.
- `close` events for files that weren't changed are dropped.
- Read-only opens of system files, Xcode, Homebrew and the reviewer's own
  home and temporary folders are counted instead of logged. Reads anywhere
  else (other users' files, /etc, /opt/ci, /Volumes) are kept.

On exit it writes es-dropped.json with what was counted instead of logged.

Usage: audit-es-filter.py <reviewer uid> <reviewer home> <output folder> <rotate seconds>
"""

import collections
import gzip
import json
import os
import sys
import time

uid, home, out_dir, rotate_seconds = int(sys.argv[1]), sys.argv[2].rstrip("/"), sys.argv[3], int(sys.argv[4])

# Read-only opens under these are counted, not logged.
QUIET_READS = (
    "/System/", "/usr/", "/bin/", "/sbin/", "/dev/",
    "/Library/Apple/", "/Library/Developer/CoreSimulator/", "/Library/Frameworks/",
    "/Applications/Xcode", "/opt/homebrew/", "/private/var/db/", "/private/var/folders/",
    home + "/",
)
FWRITE = 0x2

dropped = collections.Counter()
kept = 0
part_number = 0
part = None
part_started = 0.0


def part_path(number, temporary=False):
    return os.path.join(out_dir, f"es-events.{number:05d}.jsonl.gz" + (".tmp" if temporary else ""))


def finish_part():
    global part
    if part is not None:
        part.close()
        os.rename(part_path(part_number, temporary=True), part_path(part_number))
        part = None


def write(line):
    global part, part_number, part_started, kept
    now = time.monotonic()
    if part is not None and now - part_started >= rotate_seconds:
        finish_part()
    if part is None:
        part_number += 1
        part = gzip.open(part_path(part_number, temporary=True), "wt", compresslevel=1, encoding="utf-8")
        part_started = now
    part.write(line + "\n")
    kept += 1


def quiet_read(event):
    body = event.get("open")
    if not isinstance(body, dict) or (body.get("fflag") or 0) & FWRITE:
        return None
    path = (body.get("file") or {}).get("path") or ""
    for prefix in QUIET_READS:
        if path.startswith(prefix):
            return "~/" if prefix == home + "/" else prefix
    return None


try:
    for raw in sys.stdin:
        try:
            message = json.loads(raw)
        except ValueError:
            dropped["not JSON"] += 1
            continue
        token = (message.get("process") or {}).get("audit_token") or {}
        if token.get("euid") != uid and token.get("ruid") != uid:
            continue
        event = message.get("event") or {}
        if isinstance(event.get("exec"), dict):
            event["exec"]["env"] = "(removed)"
        close = event.get("close")
        if isinstance(close, dict) and not close.get("modified"):
            dropped["close of an unchanged file"] += 1
            continue
        prefix = quiet_read(event)
        if prefix:
            dropped[f"read-only open under {prefix}"] += 1
            continue
        write(json.dumps(message, separators=(",", ":")))
finally:
    finish_part()
    with open(os.path.join(out_dir, "es-dropped.json"), "w") as f:
        json.dump({"kept": kept, "parts": part_number, "counted_not_logged": dict(dropped.most_common())}, f, indent=2)
