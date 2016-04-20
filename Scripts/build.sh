if [ ! $TRAVIS ]; then
	TRAVIS_XCODE_WORKSPACE=WordPress.xcworkspace
	TRAVIS_XCODE_SCHEME=WordPress
        TRAVIS_XCODE_SDK=iphonesimulator
fi

xcodebuild build test \
        -destination "platform=iOS Simulator,name=iPhone 6" \
	-workspace "$TRAVIS_XCODE_WORKSPACE" \
	-scheme "$TRAVIS_XCODE_SCHEME" \
	-sdk "$TRAVIS_XCODE_SDK" \
	-configuration Debug | xcpretty -c && exit ${PIPESTATUS[0]}




	
