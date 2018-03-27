#!/bin/bash

executable=$(basename "$0" ".sh")

if [ $# -ne 3 ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	echo "*** Error!"
    echo "usage: $executable workspacePath scheme exportPath"
    echo "example: $executable WordPress.xcworkspace WordPress ~/Desktop/WordPress/ Debug Release"
    echo ""
    exit -1
fi

workspacePath="$1"
scheme="$2"
exportPath="$3"

if [ ! -e "$workspacePath" ]; then
	echo "The specified workspace file does not exist."
	exit -1
fi

if [ -e exportPath ]; then
	echo "The specified exportPath matches an existing file."
	exit -1
fi

tmpDir="$(mktemp -d)"
archiveFile="$tmpDir/archive.xcarchive"
dsymDir="$tmpDir/archive.xcarchive/dSYMs"
logFile="$tmpDir/exportipa.log"

function finish {
	echo "Log location: $logFile"
}

trap finish EXIT

echo "*** Configuration:"
echo "archiveFile = $archiveFile"
echo "dsymDir = $dsymDir"
echo "exportPath = $exportPath"
echo "scheme = $scheme"
echo "tmpDir = $tmpDir"
echo "workspacePath = $workspacePath"
echo ""
echo "*** Cleaning for testing."
xcodebuild -workspace "$workspacePath" -scheme "$scheme" clean -destination "platform=iOS Simulator,name=iPhone 8" >> "$logFile" 2>&1 || exit 1
echo "*** Testing."
xcodebuild -workspace "$workspacePath" -scheme "$scheme" test -destination "platform=iOS Simulator,name=iPhone 8" >> "$logFile" 2>&1 || exit 1
echo "*** Cleaning for building."
# The clean command for release builds seems to require the configuration to be set.
xcodebuild -workspace "$workspacePath" -scheme "$scheme" clean -configuration 'Release' >> "$logFile" 2>&1 || exit 1
echo "*** Building."
xcodebuild -workspace "$workspacePath" -scheme "$scheme" archive -archivePath "$archiveFile" >> "$logFile" 2>&1 || exit 1
echo "*** Exporting IPA."
xcodebuild -exportArchive -archivePath "$archiveFile" -exportOptionsPlist exportOptions.plist -exportPath "$exportPath" >> "$logFile"  2>&1 || exit 1
echo "*** Archiving and exporting DSYM."
ditto -c -k --sequesterRsrc --keepParent "$dsymDir" "$exportPath/dSYMs.zip"
echo ""
echo "*** Completed!!"
echo "IPA location: $exportPath"
