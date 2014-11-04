#!/bin/sh

#checking if xcpretty is available to use
pretty="xcpretty -c && exit ${PIPESTATUS[0]}"
command -v xcpretty >/dev/null
if [ $? -eq 1 ]; then
echo >&2 "xcpretty not found don't use it."
pretty="&>";
fi
#run tests using iPhone 6 simulator on iOS 8
xcodebuild -workspace WordPress.xcworkspace -scheme UITests -sdk iphonesimulator8.1 -destination 'platform=iOS Simulator,name=iPhone 6' test | ${pretty}
