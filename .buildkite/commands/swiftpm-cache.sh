#!/bin/bash -eu

# Usage: swiftpm-cache.sh restore|save
#
# Restores or saves SwiftPM's shared cache, under the same key as the a8c-ci-toolkit
# `install_swiftpm_dependencies` command. Unlike that command, `restore` doesn't resolve
# the packages: `xcodebuild` resolves them itself when it builds, so resolving them here
# as well would do the work twice. Call `save` after `xcodebuild` has resolved the packages.

SPM_CACHE_LOCATION="${HOME}/Library/Caches/org.swift.swiftpm"
PACKAGE_RESOLVED="$(dirname "${BASH_SOURCE[0]}")/../../Modules/Package.resolved"
CACHE_KEY="${BUILDKITE_PIPELINE_SLUG}-spm-cache-$(hash_file "${PACKAGE_RESOLVED}")"

case "${1:-}" in
  restore)
    mkdir -p "${SPM_CACHE_LOCATION}"
    pushd "${SPM_CACHE_LOCATION}"
    restore_cache "${CACHE_KEY}"
    popd

    # Let Xcode use the system SSH config, and trust GitHub and Bitbucket, to download packages
    sudo defaults write com.apple.dt.Xcode IDEPackageSupportUseBuiltinSCM YES
    add_host_to_ssh_known_hosts bitbucket.org
    add_host_to_ssh_known_hosts github.com
    ;;
  save)
    # Checkouts are quick to recreate, and cached artifacts break some packages
    rm -rf "${SPM_CACHE_LOCATION}/checkouts" "${SPM_CACHE_LOCATION}/artifacts"
    save_cache "${SPM_CACHE_LOCATION}" "${CACHE_KEY}" false --use_relative_path_in_tar
    ;;
  *)
    echo "Usage: $0 restore|save"
    exit 1
    ;;
esac
