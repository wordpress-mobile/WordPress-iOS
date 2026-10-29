#!/bin/bash -eu

# Usage: swiftpm-artifacts-cache.sh restore|save <source-packages-dir> <Package.resolved>
#
# Caches the binary frameworks (wordpress-rs, Sentry, GutenbergKit…) that SwiftPM downloads into
# <source-packages-dir>/artifacts, together with the workspace-state.json that records them.
# Without the state file SwiftPM doesn't trust the folder and downloads everything again.
# <source-packages-dir> is DerivedData/SourcePackages for xcodebuild, or .build for `swift test`.

ACTION="${1:?Usage: $0 restore|save <source-packages-dir> <Package.resolved>}"
SOURCE_PACKAGES="${2:?}"
PACKAGE_RESOLVED="${3:?}"
CACHE_KEY="${BUILDKITE_PIPELINE_SLUG}-spm-artifacts-v1-$(hash_file "${PACKAGE_RESOLVED}")"

case "${ACTION}" in
  restore)
    mkdir -p "${SOURCE_PACKAGES}"
    pushd "${SOURCE_PACKAGES}"
    restore_cache "${CACHE_KEY}"
    popd
    ;;
  save)
    if [[ ! -f "${SOURCE_PACKAGES}/workspace-state.json" || ! -d "${SOURCE_PACKAGES}/artifacts" ]]; then
      echo "Nothing to save in ${SOURCE_PACKAGES}"
      exit 0
    fi
    STAGING=$(mktemp -d)
    # APFS clones, so staging the folder costs no time or space
    cp -c -R "${SOURCE_PACKAGES}/artifacts" "${STAGING}/artifacts"
    cp "${SOURCE_PACKAGES}/workspace-state.json" "${STAGING}/"
    save_cache "${STAGING}" "${CACHE_KEY}" false --use_relative_path_in_tar
    rm -rf "${STAGING}"
    ;;
  *)
    echo "Usage: $0 restore|save <source-packages-dir> <Package.resolved>"
    exit 1
    ;;
esac
