#!/bin/bash -eu

# Run this at the start to fail early if value not available
echo '--- :test-analytics: Configuring Test Analytics'
export BUILDKITE_ANALYTICS_TOKEN=$BUILDKITE_ANALYTICS_TOKEN_UNIT_TESTS

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products-wordpress.tar
tar -xf build-products-wordpress.tar

echo "--- :rubygems: Setting up Gems"
install_gems

bundle exec fastlane code_freeze
