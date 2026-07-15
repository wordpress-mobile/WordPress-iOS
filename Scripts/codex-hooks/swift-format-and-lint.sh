#!/bin/sh
# Codex PostToolUse hook: format and lint Swift files edited through apply_patch.
# Codex provides the applied patch in tool_input.command, while Claude Code provides
# the edited path directly. Support both payloads so the hook remains easy to reuse.

files=$(jq -r '
    .tool_input.file_path? // empty,
    ((.tool_input.command? // .tool_input.patch? // "") | split("\n")[] |
        if startswith("*** Update File: ") then ltrimstr("*** Update File: ")
        elif startswith("*** Add File: ") then ltrimstr("*** Add File: ")
        else empty
        end)
' | awk '/\.swift$/ { print }' | sort -u)

[ -n "$files" ] || exit 0

for file in $files; do
    [ -f "$file" ] || continue
    xcrun swift format --in-place "$file" 2>/dev/null || true
done

command -v rake >/dev/null 2>&1 || exit 0

status=0
for file in $files; do
    [ -f "$file" ] || continue
    out=$(rake -s "lint[$file]" 2>&1)
    if [ -n "$out" ]; then
        echo "$out" >&2
        status=2
    fi
done

exit "$status"
