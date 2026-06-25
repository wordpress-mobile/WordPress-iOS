#!/bin/bash -eu

# Verifies that the build-free String Catalog generation (xcstringstool extract/sync) captures every string
# the legacy genstrings flow finds over the same source — guarding against extraction regressions (e.g. the
# same-basename .stringsdata collision). Runs on the `mac` queue (needs Xcode's genstrings/xcstringstool).

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type validation; then
  exit 0
fi

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :writing_hand: Copy Files"
mkdir -pv ~/.configure/wordpress-ios/secrets
cp -v fastlane/env/project.env-example ~/.configure/wordpress-ios/secrets/project.env

echo "--- :package: Generate Localizable.xcstrings from source"
bundle exec fastlane ios generate_strings_catalog

echo "--- :mag: Verify the catalog covers every genstrings string"
bundle exec fastlane ios verify_strings_catalog
