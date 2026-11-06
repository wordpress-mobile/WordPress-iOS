#!/bin/bash -eu

# Composes the App Store screenshots from the raw ones every screenshot job uploaded.

echo "--- 📦 Downloading the raw screenshots"
buildkite-agent artifact download "fastlane/jetpack_screenshots/**/*.png" .

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- 🖼️ Composing"
bundle exec fastlane create_jetpack_promo_screenshots

echo "--- 📦 Zipping the screenshots"
# In the folder layout `update_jetpack_metadata_on_app_store_connect` uploads from.
(cd fastlane && zip -rq jetpack_promo_screenshots.zip jetpack_promo_screenshots)
