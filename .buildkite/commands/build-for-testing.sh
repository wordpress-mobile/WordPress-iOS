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

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh" --artifacts DerivedData/SourcePackages

source "$(dirname "${BASH_SOURCE[0]}")/install-a8c-secrets.sh"

echo "--- :hammer_and_wrench: Building"
SCAN_RESULT_BUNDLE=1 bundle exec fastlane "build_${APP}_for_testing"

echo "--- :stopwatch: Upload build timeline"
SCHEME="$(tr '[:lower:]' '[:upper:]' <<< "${APP:0:1}")${APP:1}"
XCRESULT="fastlane/test_output/${SCHEME}.xcresult"
xcrun xcresulttool get log --type build --path "$XCRESULT" > "build-log-${APP}.json"
gzip -k "build-log-${APP}.json"
buildkite-agent artifact upload "build-log-${APP}.json.gz"
TASKS=$(jq '[.. | objects | select(.duration? != null)] | length' "build-log-${APP}.json")
echo "Build log holds ${TASKS} timed tasks"
if [[ "$TASKS" -lt 1000 ]]; then
  echo "Expected a per-task build timeline, but found only ${TASKS} timed tasks"
  exit 1
fi

echo "--- :swift: Saving Swift Packages cache"
save_swiftpm_cache --package-resolved Modules/Package.resolved --artifacts DerivedData/SourcePackages

echo "--- :arrow_up: Upload Build Products"
tar -cf "build-products-${APP}.tar" DerivedData/Build/Products/
upload_artifact "build-products-${APP}.tar"
