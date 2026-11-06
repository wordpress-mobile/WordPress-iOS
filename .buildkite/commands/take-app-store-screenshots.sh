#!/bin/bash -eu

# Takes the App Store screenshots for one device and one language, from the app the build step built.
# Usage: take-app-store-screenshots.sh DEVICE LOCALE

DEVICE=${1:?Usage $0 DEVICE LOCALE}
LOCALE=${2:?Usage $0 DEVICE LOCALE}

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products-jetpack.tar
tar -xf build-products-jetpack.tar

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- 📸 Taking the screenshots: $DEVICE, $LOCALE"
bundle exec fastlane jetpack_screenshots language:"$LOCALE" device:"$DEVICE" skip_build:true
