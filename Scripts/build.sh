#!/bin/sh

set -o pipefail

if [ $TRAVIS ]; then
  XCODE_WORKSPACE=$TRAVIS_XCODE_WORKSPACE
  XCODE_SCHEME=$TRAVIS_XCODE_SCHEME
  XCODE_SDK=$TRAVIS_XCODE_SDK
else
  XCODE_WORKSPACE=WordPress.xcworkspace
  XCODE_SCHEME=WordPress
  XCODE_SDK=iphonesimulator
fi

function build() {
xcodebuild build test \
  -destination "platform=iOS Simulator,name=iPhone 6" \
  -workspace "$XCODE_WORKSPACE" \
  -scheme "$XCODE_SCHEME" \
  -sdk "$XCODE_SDK" \
  -configuration Debug
}

function pretty_travis() {
  xcpretty -c
}

function pretty_circleci() {
  xcpretty -c --report junit --output $CIRCLE_TEST_REPORTS/xcode/results.xml
}

function rawlog_circleci() {
  tee $CIRCLE_ARTIFACTS/xcode_raw.log
}

if [ $CIRCLECI ];then
  build | rawlog_circleci | pretty_circleci
else
  build | pretty_travis
fi
