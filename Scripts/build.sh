echo "xcodebuild build -workspace $TRAVIS_XCODE_WORKSPACE -scheme $TRAVIS_XCODE_SCHEME -sdk $TRAVIS_XCODE_SDK"
xctool build -workspace "$TRAVIS_XCODE_WORKSPACE" -scheme "$TRAVIS_XCODE_SCHEME" -sdk "$TRAVIS_XCODE_SDK"
