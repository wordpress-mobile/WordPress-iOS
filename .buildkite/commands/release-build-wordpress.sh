#!/bin/bash -eu

echo "--- :beer: Installing Homebrew Dependencies"
# Sentry CLI needs to be up-to-date
brew upgrade sentry-cli

brew tap FelixHerrmann/tap
brew install swift-package-list

brew install imagemagick
brew install ghostscript

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_and_upload_app_store_connect \
  skip_confirm:true \
  skip_prechecks:true \
  create_release:true \
  beta_release:${1:-true} # use first call param, default to true for safety
