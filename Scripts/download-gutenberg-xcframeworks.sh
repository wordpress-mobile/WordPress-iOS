#!/usr/bin/env bash

set -euo pipefail

# Downloads and installs Gutenberg XCFrameworks with progress and on-disk caching.
#
# Usage: download-gutenberg-xcframeworks.sh [frameworks_dir]
#   frameworks_dir defaults to WordPress/Frameworks in the repository root.
#
# Runs from CI's shared set-up and from the build pre-action of the app schemes,
# so it exits immediately when the frameworks are already installed.

VERSION="v1.121.0"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRAMEWORKS_DIR="${1:-${REPO_ROOT}/WordPress/Frameworks}"
MARKER_FILE="${FRAMEWORKS_DIR}/.gutenberg-version"

CACHE_DIR="${HOME}/Library/Caches/WordPress-iOS/Gutenberg/${VERSION}"
DOWNLOAD_URL="https://cdn.a8c-ci.services/gutenberg-mobile/Gutenberg-${VERSION}.tar.gz"

# The xcframeworks WordPress.xcodeproj links.
REQUIRED_FRAMEWORKS=(Gutenberg React RNTAztecView hermes yoga)

frameworks_are_current() {
    [[ -f "${MARKER_FILE}" && "$(cat "${MARKER_FILE}")" == "${VERSION}" ]] || return 1
    local name
    for name in "${REQUIRED_FRAMEWORKS[@]}"; do
        [[ -d "${FRAMEWORKS_DIR}/${name}.xcframework" ]] || return 1
    done
}

if frameworks_are_current; then
    echo "Gutenberg ${VERSION} is already installed."
    exit 0
fi

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

    if ! curl --fail --location --progress-bar "${DOWNLOAD_URL}" \
        | tar xzf - -C "${TEMP_DIR}"; then
        echo "error: $(basename "$0") could not download ${DOWNLOAD_URL}" >&2
        exit 1
    fi

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

    # Promote the temp directory to the final cache path, unless a concurrent run
    # (another scheme or worktree building at the same time) already did.
    if [[ -d "${CACHE_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
    else
        mv "${TEMP_DIR}" "${CACHE_DIR}"
    fi
    # If that run won between the check and the `mv`, `mv` moved the temp
    # directory inside the cache instead of replacing it.
    rm -rf "${CACHE_DIR:?}/$(basename "${TEMP_DIR}")"
    trap - EXIT
fi

# Copy cached contents into the project.
if [[ -z "${FRAMEWORKS_DIR}" || "${FRAMEWORKS_DIR}" == "/" ]]; then
    echo "Error: invalid frameworks directory: '${FRAMEWORKS_DIR}'" >&2
    exit 1
fi
mkdir -p "${FRAMEWORKS_DIR}"
rm -f "${MARKER_FILE}"
# Replace each item rather than merging into it, so no files from another version remain.
for item in "${CACHE_DIR}"/*; do
    rm -rf "${FRAMEWORKS_DIR:?}/$(basename "${item}")"
done
# `-c` clones the files on APFS instead of copying 185 MB.
cp -a -c "${CACHE_DIR}/." "${FRAMEWORKS_DIR}/" 2> /dev/null \
    || cp -a "${CACHE_DIR}/." "${FRAMEWORKS_DIR}/"
echo "${VERSION}" > "${MARKER_FILE}"

# When run from a scheme pre-action, discard cached build plans. A plan made while
# the frameworks were missing keeps failing with "There is no XCFramework found"
# after they are installed.
if [[ -n "${OBJROOT:-}" ]]; then
    rm -rf "${OBJROOT}"/XCBuildData/*.xcbuilddata
fi

echo "Gutenberg ${VERSION} setup complete."
