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
bundle exec fastlane build_${APP}_for_testing

echo "--- :arrow_up: Upload Build Products"
tar -cf build-products-${APP}.tar DerivedData/Build/Products/
upload_artifact build-products-${APP}.tar
