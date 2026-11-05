#!/bin/bash -eu

# Builds what the App Store screenshot jobs run, for the app in SCREENSHOTS_APP (`jetpack` or
# `wordpress`): the Jetpack app and its UI tests, and the WordPress app for its screenshots.

APP=${SCREENSHOTS_APP:-jetpack}

"$(dirname "${BASH_SOURCE[0]}")/install-swift-package-list.sh"

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

"$(dirname "${BASH_SOURCE[0]}")/install-secrets.sh"

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_for_app_store_screenshots app:"$APP"

echo "--- :arrow_up: Upload Build Products"
tar -cf build-products-screenshots.tar DerivedData/Build/Products/
upload_artifact build-products-screenshots.tar
