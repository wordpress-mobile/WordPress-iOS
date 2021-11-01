#!/bin/bash -eu

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products.tar
tar -xf build-products.tar

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- 🧪 Testing"
bundle exec fastlane test_without_building name:WordPressUnitTests try_count:3
