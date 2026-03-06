#!/bin/bash
set -euo pipefail

# Downloads and installs Gutenberg XCFrameworks with progress and on-disk caching.
#
# Usage: download-gutenberg-xcframeworks.sh <version> <frameworks_dir>
# Example: download-gutenberg-xcframeworks.sh v1.121.0 WordPress/Frameworks

VERSION="${1:?Usage: $0 <version> <frameworks_dir>}"
FRAMEWORKS_DIR="${2:?Usage: $0 <version> <frameworks_dir>}"

CACHE_DIR="${HOME}/Library/Caches/WordPress-iOS/Gutenberg/${VERSION}"
DOWNLOAD_URL="https://cdn.a8c-ci.services/gutenberg-mobile/Gutenberg-${VERSION}.tar.gz"

# Download and extract into the cache if this version isn't cached yet.
if [[ -d "${CACHE_DIR}" ]]; then
    echo "Using cached Gutenberg ${VERSION}"
else
    echo "Downloading Gutenberg ${VERSION}..."
    mkdir -p "${CACHE_DIR}"

    curl --fail --location --progress-bar "${DOWNLOAD_URL}" \
        | tar xzf - -C "${CACHE_DIR}"

    # Move xcframeworks up from the nested Frameworks/ directory.
    if [[ -d "${CACHE_DIR}/Frameworks" ]]; then
        mv "${CACHE_DIR}"/Frameworks/*.xcframework "${CACHE_DIR}/"
        rm -rf "${CACHE_DIR}/Frameworks"
    fi

    # Create dSYMs directories that Xcode expects for hermes.
    mkdir -p \
        "${CACHE_DIR}/hermes.xcframework/ios-arm64/dSYMs" \
        "${CACHE_DIR}/hermes.xcframework/ios-arm64_x86_64-simulator/dSYMs"

    # Clean up leftover files from the archive.
    rm -f "${CACHE_DIR}/dummy.txt"
fi

# Copy cached frameworks into the project.
rm -rf "${FRAMEWORKS_DIR}"
mkdir -p "${FRAMEWORKS_DIR}"
cp -a "${CACHE_DIR}/"*.xcframework "${FRAMEWORKS_DIR}/"

echo "Gutenberg ${VERSION} setup complete."
