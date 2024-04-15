#!/bin/bash -eu

# Sentry CLI needs to be up-to-date
brew upgrade sentry-cli

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :swift: Setting up Swift Packages"
install_swiftpm_dependencies

echo "--- Test unstable internal pods annotation"
bundle exec fastlane test_check_pods_references

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_and_upload_wordpress_prototype_build
