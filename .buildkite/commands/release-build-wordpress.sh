#!/bin/bash -eu

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"
"$(dirname "${BASH_SOURCE[0]}")/shared-set-up-distribution.sh"

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_and_upload_app_store_connect \
  skip_confirm:true \
  skip_prechecks:true \
  create_release:true \
  beta_release:${1:-true} # use first call param, default to true for safety
