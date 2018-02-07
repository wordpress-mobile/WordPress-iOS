#!/bin/bash

ipaName="WordPress.ipa"
tmpDir="$(mktemp -d)"

archiveFile="$tmpDir/archive.xcarchive"
ipaFile="$tmpDir/$ipaName"

xcodebuild -workspace ../../WordPress.xcworkspace -scheme WordPress -configuration "Release" archive -archivePath "$archiveFile"
xcodebuild -exportArchive -archivePath "$archiveFile" -exportOptionsPlist exportOptions.plist -exportPath "$ipaFile"

echo "*** Built WPiOS with parameters:"
echo "archiveFile = $archiveFile"
echo "ipaFile = $ipaFile"
echo "ipaName = $ipaName"
echo "tmpDir = $tmpDir"
