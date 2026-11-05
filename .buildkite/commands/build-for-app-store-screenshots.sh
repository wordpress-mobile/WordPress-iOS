#!/bin/bash -eu

# Builds what the App Store screenshot jobs run for an app, `jetpack` or `wordpress`: the Jetpack app
# and its UI tests, and the WordPress app for its screenshots. The set-up is the same as
# `build-for-testing.sh`'s.
# Usage: build-for-app-store-screenshots.sh APP

APP=${1:?Usage $0 APP}

"$(dirname "${BASH_SOURCE[0]}")/install-swift-package-list.sh"

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh" --artifacts DerivedData/SourcePackages

source "$(dirname "${BASH_SOURCE[0]}")/install-a8c-secrets.sh"

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_for_app_store_screenshots app:"$APP"

echo "--- :swift: Saving Swift Packages cache"
save_swiftpm_cache --package-resolved Modules/Package.resolved --artifacts DerivedData/SourcePackages

echo "--- :arrow_up: Upload Build Products"
tar -cf build-products-screenshots.tar DerivedData/Build/Products/
upload_artifact build-products-screenshots.tar
