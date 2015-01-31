if [ ! $TRAVIS ]; then
	TRAVIS_XCODE_WORKSPACE=WordPress.xcworkspace
	TRAVIS_XCODE_SCHEME=WordPress
    TRAVIS_XCODE_SDK=iphonesimulator8.1
fi

#checking if xcpretty is available to use
command -v xcpretty >/dev/null
if [ $? -eq 1 ]; then
echo >&2 "xcpretty not found don't use it."
xcodebuild build test \
	-destination "platform=iOS Simulator,name=iPhone 4s,OS=8.1" \
	-workspace "$TRAVIS_XCODE_WORKSPACE" \
	-scheme "$TRAVIS_XCODE_SCHEME" \
	-configuration Debug
else
xcodebuild build test \
	-destination "platform=iOS Simulator,name=iPhone 4s,OS=8.1" \
	-workspace "$TRAVIS_XCODE_WORKSPACE" \
	-scheme "$TRAVIS_XCODE_SCHEME" \
	-configuration Debug \
	-sdk "$TRAVIS_XCODE_SDK" | xcpretty -c && exit ${PIPESTATUS[0]}
fi




	
