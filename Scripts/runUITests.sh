#!/bin/sh

#checking if xcpretty is available to use
pretty="xcpretty"
command -v xcpretty >/dev/null
if [ $? -eq 1 ]; then
echo >&2 "xcpretty not found don't use it."
pretty="&>";
fi
#run tests using iPhone 6 simulator on iOS 8
xcodebuild test -workspace WordPress.xcworkspace -scheme WordPressUITests -sdk iphonesimulator10.2 -destination 'platform=iOS Simulator,name=iPhone 7' | ${pretty}
