#!/bin/bash -eu

# Builds one app and uploads it to TestFlight for internal testers.

APP="${1:?Usage: build-and-upload-testflight.sh <wordpress|jetpack|reader>}"

# The build-for-testing jobs save the Swift Package binaries cache, so it's only restored here
"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh" --artifacts DerivedData/SourcePackages
"$(dirname "${BASH_SOURCE[0]}")/shared-set-up-distribution.sh"

source "$(dirname "${BASH_SOURCE[0]}")/install-a8c-secrets.sh"

echo "--- :testflight: Building and uploading ${APP} to TestFlight"
bundle exec fastlane build_and_upload_app_for_testflight app:"${APP}"
