"""Receives Claude Code hook records for the Claude PR review audit log.

Runs as the build user, so the reviewer user can add records but can't change
or delete them. Each connection carries one hook event; it is written as one
JSON line, and only then acknowledged, so a tool never runs unlogged.

Usage: audit-hook-listener.py <log file> <port file>
"""

import datetime
import json
import socket
import socketserver
import sys
import threading

MAX_RECORD_BYTES = 16 * 1024 * 1024

log_path, port_path = sys.argv[1:3]
log = open(log_path, "a", buffering=1, encoding="utf-8")
lock = threading.Lock()


class Handler(socketserver.StreamRequestHandler):
    def handle(self):
        data = self.rfile.read(MAX_RECORD_BYTES + 1)
        try:
            record = json.loads(data[:MAX_RECORD_BYTES])
        except ValueError:
            record = data[:MAX_RECORD_BYTES].decode("utf-8", "replace")
        line = json.dumps({
            "received_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "bytes": len(data),
            "truncated": len(data) > MAX_RECORD_BYTES,
            "record": record,
        })
        with lock:
            log.write(line + "\n")
            log.flush()
        self.wfile.write(b"ok\n")


class Server(socketserver.ThreadingTCPServer):
    daemon_threads = True
    allow_reuse_address = False


server = Server(("127.0.0.1", 0), Handler)
with open(port_path, "w") as f:
    f.write(str(server.server_address[1]))
server.serve_forever()
