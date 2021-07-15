#!/bin/bash

set -e

echo "--- :rubygems: Setting up Gems"
restore_cache "$(hash_file .ruby-version)-$(hash_file Gemfile.lock)"
gem install bundler
bundle install
save_cache vendor/bundle "$(hash_file .ruby-version)-$(hash_file Gemfile.lock)"

echo "--- :cocoapods: Setting up Pods"

# Caching the specs repos and global pod cache can dramatically improve Pod times
restore_cache "$BUILDKITE_PIPELINE_SLUG-specs-repos"
restore_cache "$BUILDKITE_PIPELINE_SLUG-global-pod-cache"

restore_cache "$(hash_file Podfile.lock)"
bundle exec pod install || bundle exec pod install --repo-update --verbose
save_cache Pods "$(hash_file Podfile.lock)"

save_cache ~/.cocoapods "$BUILDKITE_PIPELINE_SLUG-specs-repo"
save_cache ~/Library/Caches/CocoaPods/ "$BUILDKITE_PIPELINE_SLUG-global-pod-cache"

echo "--- :writing_hand: Copy Files"
cp fastlane/env/project.env-example .configure-files/project.env

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_for_testing

echo "--- :arrow_up: Upload Build Products"
tar -cf build-products.tar DerivedData/Build/Products/
buildkite-agent artifact upload build-products.tar