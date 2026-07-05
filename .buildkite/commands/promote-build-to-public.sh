#!/bin/bash -eu

# Promotes the build chosen in the preceding block step to public beta. No build — just gems + secrets.

# `build_to_promote` must stay in sync with PROMOTION_META_DATA_KEY in fastlane/lanes/promote.rb,
# which is the key the gather lane writes the block-step select field under.
BUILD_CODE="$(buildkite-agent meta-data get "build_to_promote" --default "")"

if [[ -z "${BUILD_CODE}" ]]; then
  echo "+++ :x: No build was selected to promote."
  exit 1
fi

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :rocket: Promoting ${BUILD_CODE} to public beta"
bundle exec fastlane promote_build build_code:"${BUILD_CODE}"
