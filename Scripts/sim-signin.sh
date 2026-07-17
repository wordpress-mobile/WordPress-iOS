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
  -d, --device <udid|booted>     Target simulator (default: booted)
  -r, --reset                    Wipe existing app data before signing in
  -h, --help                     Show this help

Examples:
  Scripts/sim-signin.sh --wpcom-token <token>                 # Jetpack, booted simulator
  Scripts/sim-signin.sh --app wordpress --wpcom-token <token> # WordPress
  Scripts/sim-signin.sh --reset --wpcom-token <token>         # wipe existing state first
EOF
}

app="jetpack"
device="booted"
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

if [[ -z "$token" ]]; then
    echo "error: missing <bearer-token>" >&2
    usage >&2
    exit 1
fi

case "$app" in
    jetpack) bundle_id="com.automattic.jetpack" ;;
    wordpress) bundle_id="org.wordpress" ;;
    *) echo "error: unknown app '$app' (expected 'jetpack' or 'wordpress')" >&2; exit 1 ;;
esac

echo "Signing $app ($bundle_id) into WordPress.com on simulator '$device'…"

if [[ "$reset" == true ]]; then
    echo "Resetting app data…"
    xcrun simctl launch --terminate-running-process "$device" "$bundle_id" -ui-test-reset-everything
    # Give the app a moment to wipe Core Data + UserDefaults before relaunching.
    sleep 2
fi

xcrun simctl launch --terminate-running-process "$device" "$bundle_id" -wpcom-token "$token"

echo "Done. The app signs in automatically from the login screen."
