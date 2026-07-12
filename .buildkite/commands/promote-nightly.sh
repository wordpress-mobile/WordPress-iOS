#!/bin/bash -eu

# Promotes the last build of the day to the nightly group. No build — just gems + secrets.

echo "--- :rubygems: Setting up Gems"
install_gems

"$(dirname "${BASH_SOURCE[0]}")/install-secrets.sh"

echo "--- :new_moon: Promoting last build of the day to nightly beta"
# The lane refuses to run anywhere but trunk.
bundle exec fastlane promote_nightly_build
