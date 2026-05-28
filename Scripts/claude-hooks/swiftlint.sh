#!/bin/sh
# Claude Code PostToolUse hook: lint the just-edited Swift file with SwiftLint.
# Reads the hook payload (JSON) on stdin, extracts the file path, and runs `swiftlint`
# when the file is Swift and the binary is available. On violations, prints them to
# stderr and exits 2 so Claude Code feeds them back to the model for self-correction.

f=$(jq -r '.tool_input.file_path')
case "$f" in
    *.swift) ;;
    *) exit 0 ;;
esac

command -v swiftlint >/dev/null 2>&1 || exit 0

out=$(swiftlint lint --quiet "$f" 2>&1)
if [ -n "$out" ]; then
    echo "$out" >&2
    exit 2
fi
