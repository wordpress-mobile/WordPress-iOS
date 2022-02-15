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

RUN=2
TESTS_EXIT_STATUS=0
for i in $(seq $RUN); do
    echo "---- RUN $i"
    bundle exec fastlane test_without_building name:"$TEST_NAME" try_count:3 device:"$DEVICE" ios_version:"$IOS_VERSION"
    INDIVIDUAL_EXIT_STATUS=$?

    echo "---- 📦 Zipping test results Run: $i Status: $INDIVIDUAL_EXIT_STATUS"
    cd build/results/ && zip -rq WordPress-run-"$i"-status-"$INDIVIDUAL_EXIT_STATUS".xcresult.zip WordPress.xcresult
    pwd
    rm -rf WordPress.xcresult
    cd ../../
    pwd

    if [ $INDIVIDUAL_EXIT_STATUS != 0 ]; then
        TESTS_EXIT_STATUS=$INDIVIDUAL_EXIT_STATUS
    fi
done
set -e

echo "--- 🚦 Report Tests Exit Status"
exit $TESTS_EXIT_STATUS
