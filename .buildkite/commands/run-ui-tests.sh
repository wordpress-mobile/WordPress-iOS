#!/bin/bash -eu

TEST_NAME=$1
DEVICE=$2
IOS_VERSION=$3

echo "Running $TEST_NAME on $DEVICE for iOS $IOS_VERSION"

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products.tar
tar -xf build-products.tar

echo "--- :wrench: Fixing VM"
brew install openjdk@11
sudo ln -sfn /usr/local/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk

# Temporary fix until we're on the Xcode 13.1 VM
echo "--- :rubygems: Fixing Ruby Setup"
gem install bundler

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- 🔬 Testing"
xcrun simctl list >> /dev/null
rake mocks &
set +e
bundle exec fastlane test_without_building name:"$TEST_NAME" try_count:3 device:"$DEVICE" ios_version:"$IOS_VERSION"
TESTS_EXIT_STATUS=$?
set -e

if [[ "$TESTS_EXIT_STATUS" -ne 0 ]]; then
  # Keep the (otherwise collapsed) current "Testing" section open in Buildkite logs on error. See https://buildkite.com/docs/pipelines/managing-log-output#collapsing-output
  echo "^^^ +++"
  echo "UI Tests failed!"
fi

echo "--- 📦 Zipping test results"
cd build/results/ && zip -rq WordPress.xcresult.zip WordPress.xcresult

echo "--- 🚦 Report Tests Exit Status"
if [[ $TESTS_EXIT_STATUS -eq 0 ]]; then
  echo "UI Tests seems to have passed (exit code 0). All good 👍"
else
  echo "The UI Tests, ran during the '🔬 Testing' step above, have failed."
  echo "For more details about the failed tests, check the logs under the '🔬 Testing' section and the \`.xcresult\` and test reports in Buildkite artifacts."

  JUNIT_REPORT="build/results/report.junit"
  if [ -f "$JUNIT_REPORT" ]; then
    xsltproc --stringparam step_title "$BUILDKITE_LABEL" ".buildkite/commands/junit-failures-to-buildkite-annotation.xslt" "$JUNIT_REPORT" | buildkite-agent annotate --style error --context "ui-tests-$TEST_NAME-$DEVICE"
  fi
fi
exit $TESTS_EXIT_STATUS
