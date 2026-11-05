#!/bin/bash -eu

# Takes an app's App Store screenshots, `jetpack` or `wordpress`, for one device and one language,
# from the build the build step uploaded.
# Usage: take-app-store-screenshots.sh APP DEVICE LOCALE

APP=${1:?Usage $0 APP DEVICE LOCALE}
DEVICE=${2:?Usage $0 APP DEVICE LOCALE}
LOCALE=${3:?Usage $0 APP DEVICE LOCALE}

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products-screenshots.tar
tar -xf build-products-screenshots.tar

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- 📸 Taking the screenshots: $APP, $DEVICE, $LOCALE"
bundle exec fastlane "${APP}_screenshots" language:"$LOCALE" device:"$DEVICE" skip_build:true
