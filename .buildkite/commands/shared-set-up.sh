#!/bin/bash -eu

echo "--- :rubygems: Setting up Gems"
install_gems

# Any arguments, e.g. `--artifacts DerivedData/SourcePackages`, are passed to `restore_swiftpm_cache`.
# It doesn't resolve the packages: `xcodebuild` resolves them itself when it builds.
echo "--- :swift: Restoring Swift Packages cache"
restore_swiftpm_cache --package-resolved Modules/Package.resolved "$@"

echo "--- :xcode: Fetch XCFrameworks"
"$(dirname "${BASH_SOURCE[0]}")/../../Scripts/download-gutenberg-xcframeworks.sh"
