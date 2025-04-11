#!/bin/bash -eu

echo "--- :arrow_down: Downloading Artifacts"
ARTIFACTS_DIR='Artifacts' # See fastlane/Fastfile BUILD_PRODUCTS_PATH
STEP=build_asc_reader
buildkite-agent artifact download "$ARTIFACTS_DIR/*.ipa" . --step $STEP
buildkite-agent artifact download "$ARTIFACTS_DIR/*.zip" . --step $STEP

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :testflight: Uploading to App Store Connect"
bundle exec fastlane upload_to_app_store_connect_reader
