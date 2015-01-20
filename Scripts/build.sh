set -o pipefail && xcodebuild build -workspace "$TRAVIS_XCODE_WORKSPACE" -scheme "$TRAVIS_XCODE_SCHEME" -sdk "$TRAVIS_XCODE_SDK"  | xcpretty -c
