#!/bin/bash
#
# Sign an iOS Simulator into WordPress.com with a bearer token, in one command.
#
# Wraps `xcrun simctl launch`, passing the `-wpcom-token` launch argument the app reads on
# the login screen to finish WordPress.com sign-in automatically — no taps required.
# Build and install the app on the simulator first (e.g. from Xcode).

set -euo pipefail

usage() {
    cat <<'EOF'
Sign an iOS Simulator into WordPress.com with a bearer token, in one command.

Usage:
  Scripts/sim-signin.sh [options] --wpcom-token <token>
  Scripts/sim-signin.sh [options] <token>

Options:
  -t, --wpcom-token <token>      WordPress.com bearer token (or pass it positionally)
  -a, --app <jetpack|wordpress>  App to sign in (default: jetpack)
  -d, --device <udid|name>       Target simulator (default: the running one; prompts if several)
  -r, --reset                    Wipe existing app data before signing in
  -h, --help                     Show this help

Examples:
  Scripts/sim-signin.sh --wpcom-token <token>                 # Jetpack, booted simulator
  Scripts/sim-signin.sh --app wordpress --wpcom-token <token> # WordPress
  Scripts/sim-signin.sh --reset --wpcom-token <token>         # wipe existing state first

Set the token once and omit it from the command line. Resolution order:
  1. --wpcom-token (or positional)
  2. WPCOM_TOKEN environment variable
  3. ~/.wpcom-token file
  4. otherwise the script prompts you to paste one
EOF
}

app="jetpack"
device=""
reset=false
token=""

set_token() {
    if [[ -n "$token" ]]; then
        echo "error: token already set (got '$1')" >&2
        exit 1
    fi
    token="$1"
}

require_value() {
    # $1 = option name, $2 = remaining argument count ($#)
    if [[ "$2" -lt 2 ]]; then
        echo "error: $1 requires a value" >&2
        exit 1
    fi
}

resolve_device() {
    # Set `device` to a booted simulator: the only one if just one is booted, otherwise
    # prompt to choose. Errors if none are booted. Called only when --device was omitted.
    local udids=() names=() line udid name
    while IFS= read -r line; do
        udid=$(printf '%s\n' "$line" | grep -oiE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)
        [[ -z "$udid" ]] && continue
        name=$(printf '%s\n' "$line" | sed -E 's/^[[:space:]]*//; s/[[:space:]]*\([0-9A-Fa-f-]{36}\).*$//')
        udids+=("$udid")
        names+=("$name")
    done < <(xcrun simctl list devices booted | grep -F "(Booted)")

    local n=${#udids[@]}
    if [[ "$n" -eq 0 ]]; then
        echo "error: no booted simulator. Boot one (open Simulator, or 'xcrun simctl boot <udid>'), or pass --device <udid>." >&2
        exit 1
    fi
    if [[ "$n" -eq 1 ]]; then
        device="${udids[0]}"
        echo "Using the only booted simulator: ${names[0]} (${device})"
        return
    fi

    echo "Multiple simulators are booted — choose one:" >&2
    local i
    for (( i = 0; i < n; i++ )); do
        printf "  %2d) %s (%s)\n" "$(( i + 1 ))" "${names[i]}" "${udids[i]}" >&2
    done
    local sel
    while true; do
        printf "Select a simulator [1-%d]: " "$n" >&2
        if ! read -r sel; then
            echo >&2
            echo "error: no selection made; re-run with --device <udid>." >&2
            exit 1
        fi
        if [[ "$sel" =~ ^[0-9]+$ ]] && [[ "$sel" -ge 1 ]] && [[ "$sel" -le "$n" ]]; then
            device="${udids[sel - 1]}"
            echo "Using ${names[sel - 1]} (${device})"
            return
        fi
        echo "  not a valid choice: '$sel'" >&2
    done
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--wpcom-token) require_value "$1" "$#"; set_token "$2"; shift 2 ;;
        -a|--app) require_value "$1" "$#"; app="$2"; shift 2 ;;
        -d|--device) require_value "$1" "$#"; device="$2"; shift 2 ;;
        -r|--reset) reset=true; shift ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "error: unknown option '$1'" >&2; usage >&2; exit 1 ;;
        *) set_token "$1"; shift ;;
    esac
done

# Fall back to a token set once elsewhere, so it needn't be passed every launch:
# the WPCOM_TOKEN environment variable, then a ~/.wpcom-token file.
if [[ -z "$token" ]]; then
    token="${WPCOM_TOKEN:-}"
fi
if [[ -z "$token" && -f "$HOME/.wpcom-token" ]]; then
    token="$(tr -d '[:space:]' < "$HOME/.wpcom-token")"
fi

# Nothing found anywhere — prompt for one. Input is hidden, since it's a secret.
if [[ -z "$token" ]]; then
    printf "No WordPress.com token found (--wpcom-token / WPCOM_TOKEN / ~/.wpcom-token).\n" >&2
    printf "Paste a bearer token (hidden), or press Return to cancel: " >&2
    read -rs token || true
    printf "\n" >&2
    token="$(printf '%s' "$token" | tr -d '[:space:]')"
    [[ -n "$token" ]] && printf "Token received (%s chars).\n" "${#token}" >&2
fi

if [[ -z "$token" ]]; then
    echo "error: no token — pass --wpcom-token <token>, set WPCOM_TOKEN, write ~/.wpcom-token, or paste one when prompted" >&2
    usage >&2
    exit 1
fi

case "$app" in
    jetpack) bundle_id="com.automattic.jetpack" ;;
    wordpress) bundle_id="org.wordpress" ;;
    *) echo "error: unknown app '$app' (expected 'jetpack' or 'wordpress')" >&2; exit 1 ;;
esac

# When no --device was given, target the running simulator (prompting if several are booted).
if [[ -z "$device" ]]; then
    resolve_device
fi

echo "Signing $app ($bundle_id) into WordPress.com on simulator '$device'…"

if [[ "$reset" == true ]]; then
    echo "Resetting app data…"
    xcrun simctl launch --terminate-running-process "$device" "$bundle_id" -ui-test-reset-everything
    # Give the app a moment to wipe Core Data + UserDefaults before relaunching.
    sleep 2
fi

xcrun simctl launch --terminate-running-process "$device" "$bundle_id" -wpcom-token "$token"

echo "Done. The app signs in automatically from the login screen."
