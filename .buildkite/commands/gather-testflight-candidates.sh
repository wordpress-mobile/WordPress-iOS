#!/bin/bash -eu

# Lists the nightly builds, opens the "choose a build" block step, and posts the
# candidate list to Slack. No build — just gems.

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :testflight: Gathering candidates and opening the block step"
bundle exec fastlane gather_testflight_candidates
