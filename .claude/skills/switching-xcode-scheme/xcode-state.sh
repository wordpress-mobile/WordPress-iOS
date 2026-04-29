#!/bin/bash
# Read or change the active scheme of the workspace currently focused in
# the running Xcode application, and list the run destinations available
# to that workspace.
#
# Operates on Xcode's `active workspace document`. Xcode must already be
# running with at least one workspace/project open — this script does not
# launch Xcode and does not open files.
#
# Subcommands:
#   workspace              Print the path of the active workspace document.
#   schemes [substring]    List schemes (newline-delimited), optionally
#                          filtered by case-insensitive substring.
#   scheme                 Print the active scheme's name.
#   scheme <name>          Set the active scheme. <name> must match exactly.
#   destinations [substring]
#                          List run destinations (newline-delimited),
#                          optionally filtered by case-insensitive
#                          substring. Destination names already include
#                          the OS version in parens, e.g.
#                          "iPhone 17 Pro (26.4.1)".
#
# This script intentionally does NOT support reading or setting the
# active run destination. Xcode's AppleScript dictionary advertises
# `active run destination` as a property of the workspace document, but
# in Xcode 26.x reads always return `missing value` and writes appear to
# silently no-op. Until Apple fixes this, change the destination by hand
# in Xcode's toolbar, or use UI scripting via System Events (which
# requires Accessibility permission).
#
# Exit codes:
#   0  success
#   1  Xcode not running, or no workspace open, or item not found
#   2  usage error

set -euo pipefail

usage() {
    awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "$0"
    exit 2
}

# Run an AppleScript snippet against Xcode after first verifying that
# Xcode is running and that it has a workspace document open. The wrapper
# converts those preconditions into clean, single-line error messages
# instead of the noisy AppleScript stack traces you'd otherwise get.
run_osa() {
    local script="$1"
    osascript <<APPLESCRIPT
if application "Xcode" is not running then
    return "ERR:not_running"
end if
tell application "Xcode"
    if (count of workspace documents) = 0 then
        return "ERR:no_workspace"
    end if
    set ws to active workspace document
    ${script}
end tell
APPLESCRIPT
}

handle_error() {
    local result="$1"
    case "$result" in
        ERR:not_running)
            echo "error: Xcode is not running" >&2
            exit 1
            ;;
        ERR:no_workspace)
            echo "error: Xcode has no workspace or project open" >&2
            exit 1
            ;;
        ERR:scheme_not_found)
            echo "error: no scheme matching the requested name" >&2
            echo "hint: run 'xcode-state.sh schemes' to list available schemes" >&2
            exit 1
            ;;
        ERR:no_active_scheme)
            echo "error: workspace has no active scheme" >&2
            exit 1
            ;;
    esac
}

cmd_workspace() {
    local result
    result=$(run_osa 'return (path of ws as string)')
    handle_error "$result"
    echo "$result"
}

# Newline-delimited list. AppleScript's text item delimiters are the
# standard way to join a list into a string with a custom separator.
list_named() {
    local elementName="$1"
    local filter="${2:-}"
    local result
    result=$(run_osa "
        set savedTID to AppleScript's text item delimiters
        set AppleScript's text item delimiters to linefeed
        set out to (name of every $elementName of ws) as string
        set AppleScript's text item delimiters to savedTID
        return out
    ")
    handle_error "$result"
    if [[ -n "$filter" ]]; then
        echo "$result" | grep -i -- "$filter" || {
            echo "error: nothing matching '$filter'" >&2
            exit 1
        }
    else
        echo "$result"
    fi
}

cmd_schemes() {
    list_named "scheme" "${1:-}"
}

cmd_destinations() {
    list_named "run destination" "${1:-}"
}

cmd_get_scheme() {
    local result
    result=$(run_osa '
        try
            return name of active scheme of ws
        on error
            return "ERR:no_active_scheme"
        end try
    ')
    handle_error "$result"
    echo "$result"
}

cmd_set_scheme() {
    local name="$1"
    local escaped
    escaped=$(printf '%s' "$name" | sed 's/"/\\"/g')
    local result
    result=$(run_osa "
        try
            set s to first scheme of ws whose name is \"$escaped\"
        on error
            return \"ERR:scheme_not_found\"
        end try
        set active scheme of ws to s
        return name of active scheme of ws
    ")
    handle_error "$result"
    echo "$result"
}

if [[ $# -eq 0 ]]; then
    usage
fi

cmd="$1"
shift || true

case "$cmd" in
    workspace)
        [[ $# -eq 0 ]] || usage
        cmd_workspace
        ;;
    schemes)
        [[ $# -le 1 ]] || usage
        cmd_schemes "${1:-}"
        ;;
    scheme)
        if [[ $# -eq 0 ]]; then
            cmd_get_scheme
        elif [[ $# -eq 1 ]]; then
            cmd_set_scheme "$1"
        else
            usage
        fi
        ;;
    destinations)
        [[ $# -le 1 ]] || usage
        cmd_destinations "${1:-}"
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        echo "error: unknown command '$cmd'" >&2
        usage
        ;;
esac
