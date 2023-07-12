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
xcrun simctl list >> /dev/null
echo "Shutdown all simulators as the changes to plist files only take effect after reboot."
xcrun simctl shutdown all
echo "Plutil print"
for plist_file in ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/UserSettings.plist; do
  plutil -extract restrictedBool.allowPasswordAutoFill.value raw -o -  $plist_file
done
echo "Disable AutoFill Passwords"
for plist_file in ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/UserSettings.plist; do
  plutil -replace restrictedBool.allowPasswordAutoFill.value -bool NO $plist_file
done
echo "Plutil print"
for plist_file in ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/UserSettings.plist; do
  plutil -extract restrictedBool.allowPasswordAutoFill.value raw -o -  $plist_file
done
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
