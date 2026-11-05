#!/bin/bash -eu

# Takes the App Store screenshots of the app in SCREENSHOTS_APP (`jetpack` or `wordpress`) for one
# device and one language, from the build the build step uploaded.
# Usage: take-app-store-screenshots.sh DEVICE LOCALE

DEVICE=${1:?Usage $0 DEVICE LOCALE}
LOCALE=${2:?Usage $0 DEVICE LOCALE}
APP=${SCREENSHOTS_APP:-jetpack}

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products-screenshots.tar
tar -xf build-products-screenshots.tar

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- 📸 Taking the screenshots: $APP, $DEVICE, $LOCALE"
bundle exec fastlane "${APP}_screenshots" language:"$LOCALE" device:"$DEVICE" skip_build:true
