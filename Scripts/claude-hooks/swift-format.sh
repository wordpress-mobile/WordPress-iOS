#!/bin/sh
# Claude Code PostToolUse hook: format the just-edited Swift file with `swift format`.
# Reads the hook payload (JSON) on stdin, extracts the file path, and runs the formatter
# in-place when the file is Swift. Silent on success or when not applicable.

f=$(jq -r '.tool_input.file_path')
case "$f" in
    *.swift)
        xcrun swift format --in-place "$f" 2>/dev/null || true
        ;;
esac
