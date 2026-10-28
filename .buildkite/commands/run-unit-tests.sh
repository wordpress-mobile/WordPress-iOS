#!/bin/bash -eu

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type validation; then
  exit 0
fi

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products-wordpress.tar
tar -xf build-products-wordpress.tar

# Only the gems are needed here, given we run the tests on a pre-built binary
echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- 🔬 Testing"
set +e
set -o pipefail
log=$(mktemp)
start=$SECONDS
bundle exec fastlane test_without_building name:WordPressUnitTests 2>&1 | tee "$log"
TESTS_EXIT_STATUS=$?
set -e
echo "fastlane test_without_building exited $TESTS_EXIT_STATUS after $((SECONDS - start)) s"

# VALIDATION ONLY — do not merge. A deliberately failing test makes xcodebuild reach the diagnostics-collection path.
echo "--- Validate diagnostics collection flag"
failed=0
if grep -q -- '-collect-test-diagnostics never' "$log"; then
  echo "PASS: xcodebuild invoked with -collect-test-diagnostics never"
else
  echo "FAIL: xcodebuild was not invoked with -collect-test-diagnostics never"
  failed=1
fi
if grep -q 'testDeliberateFailureToTriggerDiagnosticsCollection' "$log" && [[ $TESTS_EXIT_STATUS -ne 0 ]]; then
  echo "PASS: the deliberate test failure happened"
else
  echo "FAIL: the deliberate test failure did not happen, so the diagnostics path was not exercised"
  failed=1
fi
if grep -q -E 'Timed out after 600.0 seconds|Failure collecting diagnostics' "$log"; then
  echo "FAIL: simulator diagnostics collection still ran"
  failed=1
else
  echo "PASS: no simulator diagnostics collection"
fi
exit "$failed"

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
