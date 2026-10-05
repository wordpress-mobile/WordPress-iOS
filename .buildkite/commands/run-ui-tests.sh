#!/bin/bash -eu

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type validation; then
  exit 0
fi

DEVICE=${1:?Usage $0 DEVICE}

# Only the suites that run against the fixtures in Tests/JetpackUITests/Fixtures. The others sign
# in to a real WordPress.com account, which CI doesn't have a token for.
SUITES=$(grep -lE 'class var backend: Backend \{ \.fixtures \}' Tests/JetpackUITests/Tests/*.swift \
  | xargs -n1 basename \
  | sed -e 's/\.swift$//' -e 's/^/JetpackUITests\//' \
  | paste -sd, -)

if [[ -z "$SUITES" ]]; then
  echo "Error: found no UI test suite that runs against the fixtures"
  exit 1
fi

echo "Running UI tests on $DEVICE. The iOS version will be the latest available in the CI host."
echo "Suites: $SUITES"

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products-jetpack.tar
tar -xf build-products-jetpack.tar

# Only the gems are needed here, given we run the tests on a pre-built binary
echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- 🔬 Testing"
set +e
bundle exec fastlane test_without_building name:JetpackUITests device:"$DEVICE" only_testing:"$SUITES"
TESTS_EXIT_STATUS=$?
set -e

if [[ $TESTS_EXIT_STATUS -ne 0 ]]; then
  # Keep the (otherwise collapsed) current "Testing" section open in Buildkite logs on error. See https://buildkite.com/docs/pipelines/managing-log-output#collapsing-output
  echo "^^^ +++"
  echo "UI Tests failed!"
fi

echo "--- 📦 Zipping test results"
cd build/results/ && zip -rq Jetpack.xcresult.zip Jetpack.xcresult && cd -

echo "--- 💥 Collecting Crash reports"
mkdir -p build/results/crashes
find ~/Library/Logs/DiagnosticReports -name 'Jetpack*.ips' -exec cp "{}" "build/results/crashes/" \;

echo "--- 🚦 Report Tests Status"
if [[ $TESTS_EXIT_STATUS -eq 0 ]]; then
  echo "UI Tests seems to have passed (exit code 0). All good 👍"
else
  echo "The UI Tests, ran during the '🔬 Testing' step above, have failed."
  echo "For more details about the failed tests, check the Buildkite annotation, the logs under the '🔬 Testing' section and the \`.xcresult\` and test reports in Buildkite artifacts."
fi

if [[ $BUILDKITE_BRANCH == trunk ]] || [[ $BUILDKITE_BRANCH == release/* ]]; then
    annotate_test_failures "build/results/report.junit" --slack "build-and-ship"
else
    annotate_test_failures "build/results/report.junit"
fi

exit $TESTS_EXIT_STATUS
