#!/bin/bash -eu

# echo "--- 📦 Downloading Build Artifacts"
# download_artifact build-products.tar
# tar -xf build-products.tar

# Temporary fix until we're on the Xcode 13.1 VM
# echo "--- :rubygems: Fixing Ruby Setup"
# gem install bundler

# echo "--- :rubygems: Setting up Gems"
# install_gems

echo "--- 🔬 Testing"
set +e
# bundle exec fastlane test_without_building name:WordPressUnitTests try_count:3
mkdir -p "build/results"
cp ".buildkite/unit-tests-report-sample.junit" "build/results/report.junit" && false
TESTS_EXIT_STATUS=$?
set -e

if [[ $TESTS_EXIT_STATUS -ne 0 ]]; then
  # Keep the (otherwise collapsed) current "Testing" section open in Buildkite logs on error. See https://buildkite.com/docs/pipelines/managing-log-output#collapsing-output
  echo "^^^ +++"
  echo "Unit Tests failed!"
fi

# echo "--- 📦 Zipping test results"
# cd build/results/ && zip -rq WordPress.xcresult.zip WordPress.xcresult

echo "--- 🚦 Report Tests Exit Status"
if [[ $TESTS_EXIT_STATUS -eq 0 ]]; then
  echo "Unit Tests seems to have passed (exit code 0). All good 👍"
else
  echo "The Unit Tests, ran during the '🔬 Testing' step above, have failed."
  echo "For more details about the failed tests, check the logs under the '🔬 Testing' section and the \`.xcresult\` and test reports in Buildkite artifacts."

  JUNIT_REPORT="build/results/report.junit"
  if [ -f "$JUNIT_REPORT" ]; then
    xsltproc --stringparam step_title "$BUILDKITE_LABEL" ".buildkite/commands/junit-failures-to-buildkite-annotation.xslt" "$JUNIT_REPORT" | buildkite-agent annotate --style error --context "unit-tests"
  fi
fi
exit $TESTS_EXIT_STATUS
