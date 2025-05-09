#!/bin/bash -eu

echo "--- :rubygems: Setting up Gems"
install_gems

# The push/pop is workaround for tooling not supporting a Package.swift path.
# Note that neither ours nor Apple's tooling does.
pushd "$(dirname "${BASH_SOURCE[0]}")/../../Modules"
echo "--- :swift: Setting up Swift Packages"
install_swiftpm_dependencies
popd

echo "--- :xcode: Fetch XCFrameworks"
rake dependencies
