#!/bin/bash -eu

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type validation; then
  exit 0
fi

DEVICE=${1:?Usage $0 DEVICE}

"$(dirname "${BASH_SOURCE[0]}")/boot-simulator.sh" "$DEVICE"

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products-wordpress.tar
tar -xf build-products-wordpress.tar

# Only the gems are needed here, given we run the tests on a pre-built binary
echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- 🔬 Testing"
set +e
# Naming the Simulator is what lets the lane skip resolving the Swift packages and reading the build settings.
bundle exec fastlane test_without_building name:WordPressUnitTests device:"$DEVICE" reset_simulator:false
TESTS_EXIT_STATUS=$?
set -e

if [[ $TESTS_EXIT_STATUS -ne 0 ]]; then
  # Keep the (otherwise collapsed) current "Testing" section open in Buildkite logs on error. See https://buildkite.com/docs/pipelines/managing-log-output#collapsing-output
  echo "^^^ +++"
  echo "Unit Tests failed!"
fi

echo "--- 📦 Zipping test results"
cd build/results/ && zip -rq WordPress.xcresult.zip WordPress.xcresult && cd -

echo "--- 🚦 Report Tests Status"
if [[ $TESTS_EXIT_STATUS -eq 0 ]]; then
  echo "Unit Tests seems to have passed (exit code 0). All good 👍"
else
  echo "The Unit Tests, ran during the '🔬 Testing' step above, have failed."
  echo "For more details about the failed tests, check the Buildkite annotation, the logs under the '🔬 Testing' section and the \`.xcresult\` and test reports in Buildkite artifacts."
fi

if [[ $BUILDKITE_BRANCH == trunk ]] || [[ $BUILDKITE_BRANCH == release/* ]]; then
    annotate_test_failures "build/results/report.junit" --slack "build-and-ship"
else
    annotate_test_failures "build/results/report.junit"
fi

exit $TESTS_EXIT_STATUS
