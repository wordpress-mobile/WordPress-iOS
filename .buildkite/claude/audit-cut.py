"""Copies the lines added to a growing log since the last call into a new file.

Used to upload the Claude PR review's audit logs in parts while the review
runs. Only whole lines are copied, unless --all is given (at the end, when
nothing more will be written). The position reached is kept in <state file>.

Exit status: 0 = a part was written, 1 = nothing new.

Usage: audit-cut.py [--all] <log> <state file> <part>
"""

import os
import sys

args = sys.argv[1:]
take_all = args[0] == "--all"
if take_all:
    args = args[1:]
log_path, state_path, part_path = args

try:
    offset = int(open(state_path).read().strip() or 0)
except (OSError, ValueError):
    offset = 0

try:
    with open(log_path, "rb") as log:
        log.seek(offset)
        data = log.read()
except OSError:
    sys.exit(1)

if not take_all:
    data = data[: data.rfind(b"\n") + 1]
if not data:
    sys.exit(1)

with open(part_path, "wb") as part:
    part.write(data)
with open(state_path, "w") as state:
    state.write(str(offset + len(data)))
