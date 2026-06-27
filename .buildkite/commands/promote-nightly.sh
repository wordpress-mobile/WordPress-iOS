#!/bin/bash -eu

# Promotes the last build of the day to the nightly group. No build — just gems + secrets.

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :new_moon: Promoting last build of the day to nightly beta"
# The lane refuses to run anywhere but trunk.
bundle exec fastlane promote_nightly_build
