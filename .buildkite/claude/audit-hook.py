"""Claude Code hook for the Claude PR review audit log.

Installed root-owned next to the managed settings, so the reviewer can't
change it. Sends the hook's input to the build user's listener
(audit-hook-listener.py). A PreToolUse event that can't be logged blocks the
tool (exit 2), so nothing runs without a record.

Usage: audit-hook.py <listener port>
"""

import json
import socket
import sys

port = int(sys.argv[1])
data = sys.stdin.buffer.read()

try:
    event = json.loads(data).get("hook_event_name", "")
except ValueError:
    event = ""

try:
    with socket.create_connection(("127.0.0.1", port), timeout=20) as conn:
        conn.sendall(data)
        conn.shutdown(socket.SHUT_WR)
        if conn.makefile("rb").readline().strip() != b"ok":
            raise OSError("the audit log did not acknowledge the record")
except OSError as error:
    if event == "PreToolUse":
        print(f"Blocked: this tool call could not be written to the audit log ({error}).", file=sys.stderr)
        sys.exit(2)
