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

echo "--- 🧪 Testing"
xcrun simctl list >> /dev/null
rake mocks &
set +e
echo "--- 1 – Test run 1"
bundle exec fastlane test_without_building name:"$TEST_NAME" try_count:3 device:"$DEVICE" ios_version:"$IOS_VERSION"
echo "--- 2 – Test run 2"
bundle exec fastlane test_without_building name:"$TEST_NAME" try_count:3 device:"$DEVICE" ios_version:"$IOS_VERSION"
echo "--- 3 – Test run 3"
bundle exec fastlane test_without_building name:"$TEST_NAME" try_count:3 device:"$DEVICE" ios_version:"$IOS_VERSION"
echo "--- 4 – Test run 4"
bundle exec fastlane test_without_building name:"$TEST_NAME" try_count:3 device:"$DEVICE" ios_version:"$IOS_VERSION"
echo "--- 5 – Test run 5"
bundle exec fastlane test_without_building name:"$TEST_NAME" try_count:3 device:"$DEVICE" ios_version:"$IOS_VERSION"
TESTS_EXIT_STATUS=$?
set -e

echo "--- 📦 Zipping test results"
cd build/results/ && zip -rq WordPress.xcresult.zip WordPress.xcresult

echo "--- 🚦 Report Tests Exit Status"
exit $TESTS_EXIT_STATUS
