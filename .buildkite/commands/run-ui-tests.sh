#!/bin/bash -eu

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type validation; then
  exit 0
fi

DEVICE=${1:?Usage $0 DEVICE AREA}
AREA=${2:?Usage $0 DEVICE AREA}

"$(dirname "${BASH_SOURCE[0]}")/boot-simulator.sh" "$DEVICE"

# The suites are grouped by area of the app, one folder each, and each area runs in a job of its own.
TESTS_DIR=Tests/JetpackUITests/Tests

# Only the suites that run against the fixtures in Tests/JetpackUITests/Fixtures. The others sign
# in to a real WordPress.com account, which CI doesn't have a token for.
FIXTURE_SUITE='class var backend: Backend \{ \.fixtures \}'

# A suite outside the folders the pipeline has a job for would never run here, so fail instead.
for suite in $(grep -lE "$FIXTURE_SUITE" "$TESTS_DIR"/*.swift "$TESTS_DIR"/*/*.swift 2>/dev/null); do
  area=$(basename "$(dirname "$suite")")
  if ! grep -qE "^ +- \"$area\"\$" .buildkite/pipeline.yml; then
    echo "Error: no UI Tests job runs $suite. Move it into an area's folder under $TESTS_DIR, or add its folder to the step's matrix in .buildkite/pipeline.yml."
    exit 1
  fi
done

SUITE_FILES=$(grep -lE "$FIXTURE_SUITE" "$TESTS_DIR/$AREA"/*.swift || true)

if [[ -z "$SUITE_FILES" ]]; then
  echo "Error: found no UI test suite that runs against the fixtures in $TESTS_DIR/$AREA"
  exit 1
fi

SUITES=$(echo "$SUITE_FILES" \
  | xargs -n1 basename \
  | sed -e 's/\.swift$//' -e 's/^/JetpackUITests\//' \
  | paste -sd, -)

echo "Running the $AREA UI tests on $DEVICE. The iOS version will be the latest available in the CI host."
echo "Suites: $SUITES"

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products-jetpack.tar
tar -xf build-products-jetpack.tar

# Only the gems are needed here, given we run the tests on a pre-built binary
echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- 🔬 Testing"
set +e
bundle exec fastlane test_without_building name:JetpackUITests device:"$DEVICE" only_testing:"$SUITES" reset_simulator:false
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
