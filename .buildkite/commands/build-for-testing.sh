#!/bin/bash -eu
APP=${1:-}

# Run this at the start to fail early if value not available
if [[ "$APP" != "wordpress" && "$APP" != "jetpack" ]]; then
  echo "Error: Please provide either 'wordpress' or 'jetpack' as first parameter to this script"
  exit 1
fi

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- :writing_hand: Copy Files"
mkdir -pv ~/.configure/wordpress-ios/secrets
cp -v fastlane/env/project.env-example ~/.configure/wordpress-ios/secrets/project.env

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :swift: Setting up Swift Packages"
install_swiftpm_dependencies

echo "--- :hammer_and_wrench: Building"
set +e
bundle exec fastlane build_${APP}_for_testing
BUILD_EXIT_STATUS=$?
set -e

echo "Build completed if $BUILD_EXIT_STATUS. Proceeding to upload artifacts regardless of the outcome. The step will exit with the build return code afterwards."

echo "--- :arrow_up: Upload Lint Data"
upload_artifact lint.json

echo "--- :arrow_up: Upload Build Products"
tar -cf build-products-${APP}.tar DerivedData/Build/Products/
upload_artifact build-products-${APP}.tar

exit $BUILD_EXIT_STATUS
