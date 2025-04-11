#!/bin/bash -eu

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"
"$(dirname "${BASH_SOURCE[0]}")/shared-set-up-distribution.sh"

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_for_app_store_connect_reader
