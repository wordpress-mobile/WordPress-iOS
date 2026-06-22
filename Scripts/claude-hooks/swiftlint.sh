#!/bin/sh
# Claude Code PostToolUse hook: lint the just-edited Swift file with SwiftLint.
# Reads the hook payload (JSON) on stdin, extracts the file path, and runs it through
# `rake lint` so the hook uses the exact same SwiftLint binary and configuration as
# the project lint command. On violations, prints them to stderr and exits 2 so
# Claude Code feeds them back to the model for self-correction.

f=$(jq -r '.tool_input.file_path')
case "$f" in
    *.swift) ;;
    *) exit 0 ;;
esac

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
command -v rake >/dev/null 2>&1 || exit 0

out=$(rake -s "lint[$f]" 2>&1)
if [ -n "$out" ]; then
    echo "$out" >&2
    exit 2
fi
