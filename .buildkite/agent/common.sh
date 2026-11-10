#!/bin/bash

agent_setup() {
    REPO_ROOT="$(git rev-parse --show-toplevel)"
    export REPO_ROOT
    : "${AGENT_OUTPUT_DIR:?Set AGENT_OUTPUT_DIR to an absolute output directory}"
    : "${AGENT_STATE_DIR:?Set AGENT_STATE_DIR to an absolute task state directory}"
    python3 - <<'PY'
import os
from pathlib import Path

root = Path(os.environ["REPO_ROOT"])
for name in ("AGENT_OUTPUT_DIR", "AGENT_STATE_DIR"):
    path = Path(os.environ[name])
    resolved = path.resolve()
    inside = any(parent.exists() and parent.samefile(root) for parent in (resolved, *resolved.parents))
    if not path.is_absolute() or inside:
        raise SystemExit(f"{name} must be an absolute directory outside the checkout")
PY
    umask 077
    mkdir -p "$AGENT_OUTPUT_DIR/evidence" "$AGENT_STATE_DIR"
    cd "$REPO_ROOT" || return
    if command -v a8c-secrets >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/a8c-secrets" || -e WordPress/Credentials/Secrets.swift ]]; then
        echo "Use a clean coding environment without a8c-secrets or WordPress/Credentials/Secrets.swift." >&2
        return 1
    fi
}

agent_read_simulator() {
    if [[ ! -f "$AGENT_STATE_DIR/simulator-udid" ]]; then
        echo "Run .buildkite/agent/prepare.sh before verification." >&2
        return 1
    fi
    SIMULATOR_UDID="$(cat "$AGENT_STATE_DIR/simulator-udid")"
    if [[ ! "$SIMULATOR_UDID" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]]; then
        echo "Invalid simulator UUID in task state." >&2
        return 1
    fi
}
