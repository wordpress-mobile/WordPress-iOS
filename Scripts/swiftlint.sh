#!/bin/bash

set -euo pipefail

# Runs SwiftLint via the BuildTools package plugin, which pins the SwiftLint version
# to `swiftlint_version` in .swiftlint.yml. With no paths, lints the whole project.
#
# Usage: swiftlint.sh [--fix] [path ...]
#
# SDKROOT is pinned to the macOS SDK so the plugin builds even when invoked from an
# environment that targets iOS (e.g. an Xcode run script phase).

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

args=()
paths=()
for arg in "$@"; do
    case "${arg}" in
        --fix) args+=(--fix) ;;
        /*) paths+=("${arg}") ;;
        *) paths+=("${PWD}/${arg}") ;;
    esac
done

SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" \
    swift package --package-path "${REPO_ROOT}/BuildTools" plugin \
    --allow-writing-to-directory "${REPO_ROOT}" --allow-writing-to-package-directory \
    swiftlint --working-directory "${REPO_ROOT}" --quiet \
    ${args[@]+"${args[@]}"} ${paths[@]+"${paths[@]}"}
