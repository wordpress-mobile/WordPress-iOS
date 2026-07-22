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
  Scripts/sim-signin.sh [options]

Options:
  -a, --app <jetpack|wordpress>  App to sign in (default: jetpack)
  -d, --device <udid|name>       Target simulator (default: the running one; prompts if several)
  -r, --reset                    Uninstall and reinstall the app first, for a clean slate
  -h, --help                     Show this help

Examples:
  Scripts/sim-signin.sh                  # Jetpack, booted simulator
  Scripts/sim-signin.sh --app wordpress  # WordPress
  Scripts/sim-signin.sh --reset          # reinstall for a clean slate first

The WordPress.com bearer token is read from (in order):
  1. WPCOM_TOKEN environment variable
  2. ~/.wpcom-token file
  3. otherwise the script prompts you to paste one (and offers to save it to ~/.wpcom-token)

It is deliberately NOT accepted as a command-line flag: a token passed on the command line
would be saved in your shell history. Set WPCOM_TOKEN or write ~/.wpcom-token once.
EOF
}

app="jetpack"
device=""
reset=false
token=""

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
        # `|| true` so a UUID-less line (or a SIGPIPE from `head` under `pipefail`) doesn't
        # trip `set -e` and abort the whole script before the `continue` below can skip it.
        udid=$(printf '%s\n' "$line" | grep -oiE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1 || true)
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

reset_app() {
    # A clean slate: uninstall the app (which removes its entire data container — Core Data,
    # UserDefaults, caches, cookies) and reinstall the same bundle. Unlike the in-app
    # `-ui-test-reset-everything` wipe, `simctl install` is synchronous, so there's no window to
    # race before the sign-in launch, and it clears more than just Core Data + UserDefaults.
    local app_bundle bundle_name
    app_bundle=$(xcrun simctl get_app_container "$device" "$bundle_id" app 2>/dev/null || true)
    if [[ -z "$app_bundle" || ! -d "$app_bundle" ]]; then
        echo "error: can't reset — $app ($bundle_id) isn't installed on '$device'. Build and install it first (e.g. from Xcode)." >&2
        exit 1
    fi
    bundle_name=$(basename "$app_bundle")

    # Uninstall deletes the installed bundle in place, so stage a copy to reinstall from.
    # `reset_staging` is intentionally global so the EXIT trap can clean it up at script exit.
    reset_staging=$(mktemp -d)
    trap 'rm -rf "$reset_staging"' EXIT
    cp -R "$app_bundle" "$reset_staging/$bundle_name"

    echo "Resetting $app (uninstall + reinstall for a clean slate)…"
    xcrun simctl uninstall "$device" "$bundle_id"
    xcrun simctl install "$device" "$reset_staging/$bundle_name"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--app) require_value "$1" "$#"; app="$2"; shift 2 ;;
        -d|--device) require_value "$1" "$#"; device="$2"; shift 2 ;;
        -r|--reset) reset=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "error: unknown argument '$1'" >&2; usage >&2; exit 1 ;;
    esac
done

# The token is read from the WPCOM_TOKEN environment variable, then a ~/.wpcom-token file.
# It is intentionally not a command-line argument, to keep it out of shell history.
if [[ -z "$token" ]]; then
    token="${WPCOM_TOKEN:-}"
fi
if [[ -z "$token" && -f "$HOME/.wpcom-token" ]]; then
    token="$(tr -d '[:space:]' < "$HOME/.wpcom-token")"
fi

# Nothing found anywhere — prompt for one. Input is hidden, since it's a secret.
if [[ -z "$token" ]]; then
    printf "No WordPress.com token found (WPCOM_TOKEN / ~/.wpcom-token).\n" >&2
    printf "Paste a bearer token (hidden), or press Return to cancel: " >&2
    read -rs token || true
    printf "\n" >&2
    token="$(printf '%s' "$token" | tr -d '[:space:]')"
    if [[ -n "$token" ]]; then
        printf "Token received (%s chars).\n" "${#token}" >&2
        printf "Save it to ~/.wpcom-token for next time? [y/N] " >&2
        read -r save_reply || true
        if [[ "$save_reply" =~ ^[Yy]$ ]]; then
            token_file="$HOME/.wpcom-token"
            # umask keeps the new file owner-only; chmod covers an existing, looser file.
            if (umask 077; printf '%s\n' "$token" > "$token_file"); then
                chmod 600 "$token_file" 2>/dev/null || true
                printf "Saved to %s (mode 600).\n" "$token_file" >&2
            else
                printf "warning: could not write %s; continuing without saving.\n" "$token_file" >&2
            fi
        fi
    fi
fi

if [[ -z "$token" ]]; then
    echo "error: no token — set WPCOM_TOKEN, write ~/.wpcom-token, or paste one when prompted" >&2
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
    reset_app
fi

xcrun simctl launch --terminate-running-process "$device" "$bundle_id" -wpcom-token "$token"

echo "Done. The app signs in automatically from the login screen."
