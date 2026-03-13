#!/bin/bash -eu

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type validation; then
  exit 0
fi

DEVICE=$1

echo "Running UI tests on $DEVICE. The iOS version will be the latest available in the CI host."

xcrun simctl list --json devices available

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products-jetpack.tar
tar -xf build-products-jetpack.tar

# Only the gems are needed here, given we run the tests on a pre-built binary
echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- 🔬 Testing"
xcrun simctl list >> /dev/null
rake mocks &
set +e
bundle exec fastlane test_without_building name:Jetpack device:"$DEVICE"
TESTS_EXIT_STATUS=$?
set -e

if [[ "$TESTS_EXIT_STATUS" -ne 0 ]]; then
  # Keep the (otherwise collapsed) current "Testing" section open in Buildkite logs on error. See https://buildkite.com/docs/pipelines/managing-log-output#collapsing-output
  echo "^^^ +++"
  echo "UI Tests failed!"
fi

echo "--- 📦 Zipping test results"
cd build/results/ && zip -rq JetpackUITests.xcresult.zip JetpackUITests.xcresult && cd -

echo "--- 💥 Collecting Crash reports"
mkdir -p build/results/crashes
find ~/Library/Logs/DiagnosticReports -name '*.ips' -exec cp "{}" "build/results/crashes/" \;

exit $TESTS_EXIT_STATUS
