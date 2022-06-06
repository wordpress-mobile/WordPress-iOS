#!/bin/bash -eu

# Temporary fix until we're on the Xcode 13.1 VM
echo "--- :rubygems: Fixing Ruby Setup"
gem install bundler

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :writing_hand: Copy Files"
cp -v fastlane/env/project.env-example .configure-files/project.env
mkdir -pv ~/.configure/wordpress-ios/secrets
cp -v fastlane/env/project.env-example ~/.configure/wordpress-ios/secrets/project.env

echo "--- Installing Secrets"
bundle exec fastlane run configure_apply


echo "--- 🔬 Testing"
set +e
bundle exec fastlane screenshots language:en-US skip_clean:true
TESTS_EXIT_STATUS=$?
set -e

if [[ $TESTS_EXIT_STATUS -ne 0 ]]; then
  # Keep the (otherwise collapsed) current "Testing" section open in Buildkite logs on error. See https://buildkite.com/docs/pipelines/managing-log-output#collapsing-output
  echo "^^^ +++"
  echo "Unit Tests failed!"
fi

echo "--- 📦 Zipping test results"
cd build/results/ && zip -rq WordPress.xcresult.zip WordPress.xcresult

echo "--- 🚦 Report Tests Exit Status"
if [[ $TESTS_EXIT_STATUS -eq 0 ]]; then
  echo "Unit Tests seems to have passed (exit code 0). All good 👍"
else
  echo "The Unit Tests, ran during the '🔬 Testing' step above, have failed."
  echo "For more details about the failed tests, check the logs under the '🔬 Testing' section and the \`.xcresult\` and test reports in Buildkite artifacts."
fi
exit $TESTS_EXIT_STATUS
