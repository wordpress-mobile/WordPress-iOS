"""Turns the Claude PR review's raw audit logs into readable lists.

Reads, from the audit folder:
  network.txt         pf log of the reviewer's outgoing connections (tcpdump text)
  dns.txt             DNS traffic (tcpdump text), to name the addresses

Writes processes.txt, files-read.txt, files-written.txt, privileged.txt,
event-counts.txt, es-samples.json and network-summary.txt next to them.

eslogger's JSON has no stable schema (see `man eslogger`), so every field is
read defensively, and one sample of each event type is kept to fix this
script when the schema changes.

Also reads the Endpoint Security events (eslogger, filtered by
audit-es-filter.py) from the es-events.*.jsonl.gz parts in <events folder>,
and es-dropped.json from the audit folder.

Usage: audit-summarize.py <audit folder> <reviewer uid> <events folder>
"""

import collections
import glob
import gzip
import json
import os
import re
import sys

audit_dir, uid, events_dir = sys.argv[1], int(sys.argv[2]), sys.argv[3]


def audit_path(name):
    return os.path.join(audit_dir, name)


def get(obj, *keys):
    for key in keys:
        if not isinstance(obj, dict):
            return None
        obj = obj.get(key)
    return obj


def file_path(obj):
    """A path from an es_file_t, or from an existing-file/new-path destination."""
    if not isinstance(obj, dict):
        return None
    if isinstance(obj.get("path"), str):
        return obj["path"]
    existing = get(obj, "existing_file", "path")
    if existing:
        return existing
    directory = get(obj, "new_path", "dir", "path")
    filename = get(obj, "new_path", "filename")
    if directory and filename:
        return f"{directory}/{filename}"
    return None


def es_summary():
    counts = collections.Counter()
    samples = {}
    processes = []
    reads = collections.Counter()
    writes = collections.Counter()
    privileged = []

    def event_lines():
        for part in sorted(glob.glob(os.path.join(events_dir, "es-events.*.jsonl.gz"))):
            with gzip.open(part, "rt", encoding="utf-8", errors="replace") as events:
                yield from events

    for line in event_lines():
        try:
            message = json.loads(line)
        except ValueError:
            continue
        process = message.get("process") or {}
        if get(process, "audit_token", "euid") != uid and get(process, "audit_token", "ruid") != uid:
            continue
        event = message.get("event") or {}
        kind = next(iter(event), "unknown")
        body = event.get(kind) or {}
        counts[kind] += 1
        samples.setdefault(kind, message)

        time = message.get("time", "")
        pid = get(process, "audit_token", "pid")
        exe = get(process, "executable", "path") or "?"

        if kind == "exec":
            args = body.get("args") or [get(body, "target", "executable", "path") or "?"]
            processes.append(f"{time}\tpid {get(body, 'target', 'audit_token', 'pid')}\tparent {pid}\t{json.dumps(args)}")
        elif kind == "open":
            file = file_path(body.get("file"))
            flags = body.get("fflag") or 0
            if file:
                # FWRITE is 0x2.
                (writes if flags & 0x2 else reads)[("open-write" if flags & 0x2 else "read", file)] += 1
        elif kind == "close":
            if body.get("modified"):
                writes[("modified", file_path(body.get("target")))] += 1
        elif kind == "create":
            writes[("created", file_path(body.get("destination")))] += 1
        elif kind == "rename":
            writes[("renamed", f"{file_path(body.get('source'))} -> {file_path(body.get('destination'))}")] += 1
        elif kind == "unlink":
            writes[("deleted", file_path(body.get("target")))] += 1
        elif kind == "truncate":
            writes[("truncated", file_path(body.get("target")))] += 1
        elif kind == "link":
            writes[("linked", f"{file_path(body.get('source'))} -> {get(body, 'target_dir', 'path')}/{body.get('target_filename')}")] += 1
        elif kind == "clone":
            writes[("cloned", f"{file_path(body.get('source'))} -> {get(body, 'target_dir', 'path')}/{body.get('target_name')}")] += 1
        elif kind in ("sudo", "su", "setuid", "seteuid"):
            privileged.append(f"{time}\t{kind}\t{exe}\t{json.dumps(body)[:500]}")
        elif kind == "signal":
            target = body.get("target") or {}
            if get(target, "audit_token", "euid") != uid:
                privileged.append(f"{time}\tsignal {body.get('sig')}\t{exe} -> {get(target, 'executable', 'path')} (uid {get(target, 'audit_token', 'euid')})")

    def write(name, lines):
        with open(audit_path(name), "w") as f:
            f.write("\n".join(lines) + ("\n" if lines else ""))

    write("processes.txt", processes)
    write("files-read.txt", [f"{n}\t{file}" for (_, file), n in sorted(reads.items(), key=lambda i: i[0][1] or "")])
    write("files-written.txt", [f"{op}\t{n}\t{file}" for (op, file), n in sorted(writes.items(), key=lambda i: str(i[0][1]))])
    write("privileged.txt", privileged)
    try:
        with open(audit_path("es-dropped.json")) as f:
            not_logged = json.load(f).get("counted_not_logged", {})
    except (OSError, ValueError):
        not_logged = {}
    write("event-counts.txt", [f"{kind}\t{n}" for kind, n in counts.most_common()]
          + ["", "Counted but not logged:"] + [f"{reason}\t{n}" for reason, n in not_logged.items()])
    with open(audit_path("es-samples.json"), "w") as f:
        json.dump(samples, f, indent=2)
    return counts


def network_summary():
    names = collections.defaultdict(set)
    if os.path.exists(audit_path("dns.txt")):
        queries = {}
        with open(audit_path("dns.txt"), errors="replace") as dns:
            for line in dns:
                query = re.search(r": (\d+)\+?\s+(?:\[[^\]]*\]\s+)?[A-Z]+\? (\S+?)\.? \(", line)
                if query:
                    queries[query.group(1)] = query.group(2)
                    continue
                answer = re.search(r"\.53 > \S+: (\d+)[^ ]*\s+\d+/\d+/\d+ (.*)", line)
                if answer and answer.group(1) in queries:
                    for address in re.findall(r"\b(?:A|AAAA) ([0-9a-fA-F.:]+)", answer.group(2)):
                        names[address].add(queries[answer.group(1)])

    destinations = collections.Counter()
    if os.path.exists(audit_path("network.txt")):
        with open(audit_path("network.txt"), errors="replace") as network:
            for line in network:
                match = re.search(r" > ([0-9a-fA-F.:]+)\.(\d+): (.*)", line)
                if not match:
                    continue
                protocol = "udp" if "UDP" in match.group(3) else "tcp"
                destinations[(match.group(1), match.group(2), protocol)] += 1

    lines = [
        f"{address}:{port}/{protocol}\t{count} connection(s)\t{', '.join(sorted(names.get(address, []))) or '(no DNS name seen)'}"
        for (address, port, protocol), count in destinations.most_common()
    ]
    with open(audit_path("network-summary.txt"), "w") as f:
        f.write("\n".join(lines) + ("\n" if lines else ""))
    return destinations, names


es_summary()
network_summary()
