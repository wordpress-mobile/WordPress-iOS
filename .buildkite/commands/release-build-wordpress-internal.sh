#!/bin/bash -eu

echo "--- :arrow_down: Installing Release Dependencies"
brew update # Update homebrew to temporarily fix a bintray issue
brew install imagemagick
brew install ghostscript
brew upgrade sentry-cli

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_and_upload_app_center \
  skip_confirm:true \
  skip_prechecks:true
