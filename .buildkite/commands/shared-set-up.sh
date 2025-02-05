#!/bin/bash -eu

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :swift: Setting up Swift Packages"
install_swiftpm_dependencies

echo "--- :xcode: Fetch XCFrameworks"
rake dependencies
