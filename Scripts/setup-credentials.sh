#!/bin/bash

set -euo pipefail

# Writes WordPress/Credentials/Secrets.swift with your own WordPress.com API app's
# client ID and secret, so you can log in to WordPress.com in a Debug build.
# External contributors need this; Automattic developers use `a8c-secrets decrypt`.
#
# Usage: setup-credentials.sh [--client-id <id> --client-secret <secret>]
#   Without both options, walks you through creating the app and asks for them.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_FILE="${REPO_ROOT}/WordPress/Credentials/Secrets-example.swift"
SECRETS_FILE="${REPO_ROOT}/WordPress/Credentials/Secrets.swift"

CLIENT_PLACEHOLDER='let client = "0"'
SECRET_PLACEHOLDER='let secret = "your-secret-here"'

usage() {
    echo "Usage: $(basename "$0") [--client-id <id> --client-secret <secret>]" >&2
    exit 1
}

client_id=""
client_secret=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --client-id) [[ $# -ge 2 ]] || usage; client_id="$2"; shift 2 ;;
        --client-secret) [[ $# -ge 2 ]] || usage; client_secret="$2"; shift 2 ;;
        *) usage ;;
    esac
done

# Reads one line into the named variable, failing clearly at the end of input.
read_line() {
    if ! IFS= read -r "$1"; then
        echo "error: no input. Pass --client-id and --client-secret to run without prompts." >&2
        exit 1
    fi
}

continue_after() {
    echo "$1 Please press enter to continue"
    read_line _
}

if [[ -z "${client_id}" || -z "${client_secret}" ]]; then
    divider='====================================================================================='
    echo "${divider}"
    echo 'To log in to WordPress.com in the app while developing, you need your own API credentials.'
    echo "${divider}"
    echo "1. Go to https://wordpress.com/start/user and create a WordPress.com account (if you don't already have one)."
    continue_after 'Once you have created your account,'
    echo "${divider}"
    echo '2. Now register an API application at https://developer.wordpress.com/apps/.'
    continue_after 'Once you have registered your API App,'
    echo "${divider}"
    echo '3. Make sure to set "Redirect URLs" = https://localhost and "Type" = Native, then click "Create" and "Update".'
    continue_after 'Once you have set the redirect URL and type,'
    echo "${divider}"
    continue_after 'Lastly, keep your Client ID and App Secret on hand for the next steps,'
    echo 'Please enter your Client ID'
    read_line client_id
    echo 'Please enter your Client Secret'
    read_line client_secret
fi

# The values go inside Swift string literals.
for value in "${client_id}" "${client_secret}"; do
    if [[ -z "${value}" || "${value}" == *[\"\\]* ]]; then
        echo 'error: the client ID and secret must not be empty or contain quotes or backslashes.' >&2
        exit 1
    fi
done

# Read the whole file, keeping its trailing newline.
contents="$(cat "${EXAMPLE_FILE}"; printf x)"
contents="${contents%x}"
for placeholder in "${CLIENT_PLACEHOLDER}" "${SECRET_PLACEHOLDER}"; do
    if [[ "${contents}" != *"${placeholder}"* ]]; then
        echo "error: '${placeholder}' not found in ${EXAMPLE_FILE}" >&2
        exit 1
    fi
done
# Replace by splitting around the placeholder. `${var/pattern/replacement}` treats
# quotes in the replacement differently in bash 3.2 (macOS) and 5.x.
replace() {
    local placeholder="$1" replacement="$2"
    contents="${contents%%"${placeholder}"*}${replacement}${contents#*"${placeholder}"}"
}
replace "${CLIENT_PLACEHOLDER}" "let client=\"${client_id}\""
replace "${SECRET_PLACEHOLDER}" "let secret=\"${client_secret}\""

printf '%s' "${contents}" > "${SECRETS_FILE}"
echo "Wrote your credentials to ${SECRETS_FILE}"
