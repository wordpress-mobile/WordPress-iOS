#!/bin/bash -eu

# Builds one app and uploads it to TestFlight for internal testers.

APP="${1:?Usage: build-and-upload-testflight.sh <wordpress|jetpack|reader>}"

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"
"$(dirname "${BASH_SOURCE[0]}")/shared-set-up-distribution.sh"

source "$(dirname "${BASH_SOURCE[0]}")/install-a8c-secrets.sh"

# The build-for-testing jobs save this cache, so it's only restored here
echo "--- :swift: Restoring Swift Package binaries"
"$(dirname "${BASH_SOURCE[0]}")/swiftpm-artifacts-cache.sh" restore DerivedData/SourcePackages Modules/Package.resolved

echo "--- :testflight: Building and uploading ${APP} to TestFlight"
bundle exec fastlane build_and_upload_app_for_testflight app:"${APP}"
