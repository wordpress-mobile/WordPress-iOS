#!/bin/bash -eu

# Validation script to verify the xcode-26.2 CI image has:
# 1. Metal Toolchain pre-installed (AINFRA-1646)
# 2. iOS 18.6 runtime available (AINFRA-1291)
# 3. watchOS 10.5 runtime available

echo "--- :xcode: Xcode Version"
xcodebuild -version

echo "--- :metal: Verifying Metal Toolchain"
if xcrun metal --version; then
  echo "✅ Metal Toolchain is installed"
else
  echo "❌ Metal Toolchain is NOT installed"
  exit 1
fi

echo "--- :iphone: Checking iOS 18.6 Runtime"
if xcrun simctl list runtimes | grep -q "iOS 18.6"; then
  echo "✅ iOS 18.6 runtime is available"
  xcrun simctl list runtimes | grep "iOS 18"
else
  echo "❌ iOS 18.6 runtime is NOT available"
  xcrun simctl list runtimes
  exit 1
fi

echo "--- :watch: Checking watchOS 10.5 Runtime"
if xcrun simctl list runtimes | grep -q "watchOS 10.5"; then
  echo "✅ watchOS 10.5 runtime is available"
  xcrun simctl list runtimes | grep "watchOS 10"
else
  echo "❌ watchOS 10.5 runtime is NOT available"
  xcrun simctl list runtimes
  exit 1
fi

echo "--- :test_tube: Creating test simulators"
echo "Creating iOS 18.6 simulator..."
xcrun simctl create "Test-iOS18-Validation" "iPhone 15" "iOS 18.6" || echo "Failed to create iOS 18.6 simulator (may already exist)"

echo "Creating watchOS 10.5 simulator..."
xcrun simctl create "Test-watchOS10-Validation" "Apple Watch Series 9 (45mm)" "watchOS 10.5" || echo "Failed to create watchOS 10.5 simulator (may already exist)"

echo "--- :broom: Cleaning up test simulators"
xcrun simctl delete "Test-iOS18-Validation" || true
xcrun simctl delete "Test-watchOS10-Validation" || true

echo "--- :white_check_mark: All validations passed!"
