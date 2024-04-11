#!/bin/bash -eu

# Run this at the start to fail early if value not available
echo '--- :test-analytics: Configuring Test Analytics'
export BUILDKITE_ANALYTICS_TOKEN=$BUILDKITE_ANALYTICS_TOKEN_UNIT_TESTS

echo "--- :rubygems: Setting up Gems"
install_gems

echo '--- :closed_lock_with_key: Access secrets'
bundle exec fastlane run configure_apply

echo '--- TEST FOR CI ANNOTATION ON PODS CHECK'
bundle exec fastlane code_freeze
