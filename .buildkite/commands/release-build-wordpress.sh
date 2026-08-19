#!/bin/bash -eu

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"
"$(dirname "${BASH_SOURCE[0]}")/shared-set-up-distribution.sh"

"$(dirname "${BASH_SOURCE[0]}")/install-secrets.sh"

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_and_upload_app_store_connect \
  skip_confirm:true \
  skip_prechecks:true \
  create_release:true \
  beta_release:${1:-true} # use first call param, default to true for safety
