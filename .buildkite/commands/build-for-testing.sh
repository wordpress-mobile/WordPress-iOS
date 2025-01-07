#!/bin/bash -eu
APP=${1:-}

# Run this at the start to fail early if value not available
if [[ "$APP" != "wordpress" && "$APP" != "jetpack" ]]; then
  echo "Error: Please provide either 'wordpress' or 'jetpack' as first parameter to this script"
  exit 1
fi

echo "--- :beer: Installing Homebrew Dependencies"
brew tap FelixHerrmann/tap
brew install swift-package-list

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

echo "--- :writing_hand: Copy Files"
mkdir -pv ~/.configure/wordpress-ios/secrets
cp -v fastlane/env/project.env-example ~/.configure/wordpress-ios/secrets/project.env

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_${APP}_for_testing

echo "--- :arrow_up: Upload Build Products"
tar -cf build-products-${APP}.tar DerivedData/Build/Products/
upload_artifact build-products-${APP}.tar
