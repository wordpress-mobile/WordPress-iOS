#!/bin/bash -eu

# Builds one app and uploads it to TestFlight for internal testers.
#
# Part of the "Faster Releases for WordPress and Jetpack" RFC. CI runs one
# invocation per app (in parallel) via the matrix step in pipeline.yml.

APP="${1:?Usage: build-and-upload-testflight.sh <wordpress|jetpack|reader>}"

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"
"$(dirname "${BASH_SOURCE[0]}")/shared-set-up-distribution.sh"

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :hammer_and_wrench: Building and uploading ${APP} to TestFlight"
bundle exec fastlane build_and_upload_app_for_testflight app:"${APP}"
