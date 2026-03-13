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
bundle exec fastlane test_without_building name:WordPressUnitTests
TESTS_EXIT_STATUS=$?
set -e

if [[ $TESTS_EXIT_STATUS -ne 0 ]]; then
  # Keep the (otherwise collapsed) current "Testing" section open in Buildkite logs on error. See https://buildkite.com/docs/pipelines/managing-log-output#collapsing-output
  echo "^^^ +++"
  echo "Unit Tests failed!"
fi

echo "--- 📦 Zipping test results"
cd build/results/ && zip -rq WordPress.xcresult.zip WordPress.xcresult && cd -

exit $TESTS_EXIT_STATUS
