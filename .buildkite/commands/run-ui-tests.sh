#!/bin/bash -eu

DEVICE=$1

echo "Running UI tests on $DEVICE. The iOS version will be the latest available in the CI host."

# Run this at the start to fail early if value not available
echo '--- :test-analytics: Configuring Test Analytics'
if [[ $DEVICE =~ ^iPhone ]]; then
  export BUILDKITE_ANALYTICS_TOKEN=$BUILDKITE_ANALYTICS_TOKEN_UI_TESTS_IPHONE
else
  export BUILDKITE_ANALYTICS_TOKEN=$BUILDKITE_ANALYTICS_TOKEN_UI_TESTS_IPAD
fi

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products-jetpack.tar
tar -xf build-products-jetpack.tar

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :swift: Setting up Swift Packages"
install_swiftpm_dependencies

echo "--- 🔬 Testing"
echo "LIST DEVICES"
xcrun simctl list
echo "SHUTDOWN ALL SIMULATORS"
xcrun simctl shutdown all
echo "PLIST BUDDY"
IPAD_PLIST="/Users/builder/Library/Developer/CoreSimulator/Devices/FC4B5BA1-C4A0-4C60-94FE-8C40B29C17AD/data/Containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/UserSettings.plist"
IPHONE_PLIST="/Users/builder/Library/Developer/CoreSimulator/Devices/435326FA-9F81-4C3E-96B8-92446A5B0075/data/Containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/UserSettings.plist"
/usr/libexec/PlistBuddy -c "Set :restrictedBool:allowPasswordAutoFill:value NO" $IPAD_PLIST
/usr/libexec/PlistBuddy -c "Set :restrictedBool:allowPasswordAutoFill:value NO" $IPHONE_PLIST
rake mocks &
set +e
bundle exec fastlane test_without_building name:Jetpack device:"$DEVICE"
TESTS_EXIT_STATUS=$?
set -e

if [[ "$TESTS_EXIT_STATUS" -ne 0 ]]; then
  # Keep the (otherwise collapsed) current "Testing" section open in Buildkite logs on error. See https://buildkite.com/docs/pipelines/managing-log-output#collapsing-output
  echo "^^^ +++"
  echo "UI Tests failed!"
fi

echo "--- 📦 Zipping test results"
cd build/results/ && zip -rq JetpackUITests.xcresult.zip JetpackUITests.xcresult && cd -

echo "--- 💥 Collecting Crash reports"
mkdir -p build/results/crashes
find ~/Library/Logs/DiagnosticReports -name '*.ips' -exec cp "{}" "build/results/crashes/" \;

echo "--- 🚦 Report Tests Status"
if [[ $TESTS_EXIT_STATUS -eq 0 ]]; then
  echo "UI Tests seems to have passed (exit code 0). All good 👍"
else
  echo "The UI Tests, ran during the '🔬 Testing' step above, have failed."
  echo "For more details about the failed tests, check the Buildkite annotation, the logs under the '🔬 Testing' section and the \`.xcresult\` and test reports in Buildkite artifacts."
fi

if [[ $BUILDKITE_BRANCH == trunk ]] || [[ $BUILDKITE_BRANCH == release/* ]]; then
    annotate_test_failures "build/results/JetpackUITests.xml" --slack "build-and-ship"
else
    annotate_test_failures "build/results/JetpackUITests.xml"
fi

exit $TESTS_EXIT_STATUS
