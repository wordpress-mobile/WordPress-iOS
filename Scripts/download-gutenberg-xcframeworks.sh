#!/usr/bin/env bash

set -euo pipefail

# Downloads and installs Gutenberg XCFrameworks with progress and on-disk caching.
#
# Usage: download-gutenberg-xcframeworks.sh [frameworks_dir]
#   frameworks_dir defaults to WordPress/Frameworks

VERSION="v1.121.0"
FRAMEWORKS_DIR="${1:-WordPress/Frameworks}"

CACHE_DIR="${HOME}/Library/Caches/WordPress-iOS/Gutenberg/${VERSION}"
DOWNLOAD_URL="https://cdn.a8c-ci.services/gutenberg-mobile/Gutenberg-${VERSION}.tar.gz"

# Download and extract into the cache if this version isn't cached yet.
if [[ -d "${CACHE_DIR}" ]]; then
    echo "Using cached Gutenberg ${VERSION}"
else
    echo "Downloading Gutenberg ${VERSION}..."

    # Extract into a temp directory first so a partial download doesn't
    # leave a corrupt cache that persists across runs.
    mkdir -p "$(dirname "${CACHE_DIR}")"
    TEMP_DIR="$(mktemp -d "${CACHE_DIR}.XXXXXX")"
    trap 'rm -rf "${TEMP_DIR}"' EXIT

    curl --fail --location --progress-bar "${DOWNLOAD_URL}" \
        | tar xzf - -C "${TEMP_DIR}"

    # Move contents up from the nested Frameworks/ directory.
    if [[ -d "${TEMP_DIR}/Frameworks" ]]; then
        mv "${TEMP_DIR}"/Frameworks/* "${TEMP_DIR}/"
        rm -rf "${TEMP_DIR}/Frameworks"
    fi

    # Create dSYMs directories that Xcode expects for hermes.
    mkdir -p \
        "${TEMP_DIR}/hermes.xcframework/ios-arm64/dSYMs" \
        "${TEMP_DIR}/hermes.xcframework/ios-arm64_x86_64-simulator/dSYMs"

    # Clean up leftover files from the archive.
    rm -f "${TEMP_DIR}/dummy.txt"

    # Atomically promote the temp directory to the final cache path.
    mv "${TEMP_DIR}" "${CACHE_DIR}"
    trap - EXIT
fi

# Copy cached contents into the project.
if [[ -z "${FRAMEWORKS_DIR}" || "${FRAMEWORKS_DIR}" == "/" ]]; then
    echo "Error: invalid frameworks directory: '${FRAMEWORKS_DIR}'" >&2
    exit 1
fi
cp -a "${CACHE_DIR}" "${FRAMEWORKS_DIR}"

echo "Gutenberg ${VERSION} setup complete."
