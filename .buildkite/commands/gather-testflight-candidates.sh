#!/bin/bash -eu

# Lists the nightly builds, opens the "choose a build" block step, and posts the
# candidate list to Slack. No build — just gems + secrets.

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :testflight: Gathering candidates and opening the block step"
bundle exec fastlane gather_testflight_candidates
