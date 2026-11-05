#!/bin/bash -eu

# Composes an app's App Store screenshots, `jetpack` or `wordpress`, from the raw ones every
# screenshot job uploaded.
# Usage: compose-app-store-screenshots.sh APP

APP=${1:?Usage $0 APP}
if [[ "$APP" == "jetpack" ]]; then
  LANE=create_jetpack_promo_screenshots
  PROMO=jetpack_promo_screenshots
else
  LANE=create_promo_screenshots
  PROMO=promo_screenshots
fi

echo "--- 📦 Downloading the raw screenshots"
buildkite-agent artifact download "fastlane/${APP}_screenshots/**/*.png" .

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- 🖼️ Composing"
bundle exec fastlane "$LANE"

echo "--- 📦 Zipping the screenshots"
# In the folder layout `update_${APP}_metadata_on_app_store_connect` uploads from.
(cd fastlane && zip -rq "${APP}_promo_screenshots.zip" "$PROMO")
