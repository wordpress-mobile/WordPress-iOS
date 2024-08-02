#!/bin/bash -eu


echo "--- :beer: Installing Homebrew Dependencies"
# Sentry CLI needs to be up-to-date
brew upgrade sentry-cli

brew tap FelixHerrmann/tap
brew install swift-package-list

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :swift: Setting up Swift Packages"
install_swiftpm_dependencies

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_and_upload_jetpack_prototype_build
