#!/bin/bash -eu

# FIXIT-13.1: Temporary fix until we're on the Xcode 13.1 VM
echo "--- :rubygems: Fixing Ruby Setup"
gem install bundler

echo "--- :rubygems: Setting up Gems"
restore_cache "$(hash_file .ruby-version)-$(hash_file Gemfile.lock)"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- :writing_hand: Copy Files"
cp -v fastlane/env/project.env-example .configure-files/project.env
mkdir -pv ~/.configure/wordpress-ios/secrets
cp -v fastlane/env/project.env-example ~/.configure/wordpress-ios/secrets/project.env

echo "--- Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_for_testing

echo "--- :arrow_up: Upload Build Products"
tar -cf build-products.tar DerivedData/Build/Products/
upload_artifact build-products.tar
