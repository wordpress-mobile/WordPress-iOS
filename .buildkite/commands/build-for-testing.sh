#!/bin/bash -eu

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type build; then
  exit 0
fi

APP=${1:-}

# Run this at the start to fail early if value not available
if [[ "$APP" != "wordpress" && "$APP" != "jetpack" ]]; then
  echo "Error: Please provide either 'wordpress' or 'jetpack' as first parameter to this script"
  exit 1
fi

"$(dirname "${BASH_SOURCE[0]}")/install-swift-package-list.sh"

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

source "$(dirname "${BASH_SOURCE[0]}")/install-secrets.sh"

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane "build_${APP}_for_testing"

echo "--- :arrow_up: Upload Build Products"
tar -cf "build-products-${APP}.tar" DerivedData/Build/Products/
upload_artifact "build-products-${APP}.tar"
