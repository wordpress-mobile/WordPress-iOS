#!/bin/bash -eu

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :swift: Restoring Swift Packages cache"
"$(dirname "${BASH_SOURCE[0]}")/swiftpm-cache.sh" restore

echo "--- :xcode: Fetch XCFrameworks"
"$(dirname "${BASH_SOURCE[0]}")/../../Scripts/download-gutenberg-xcframeworks.sh"
