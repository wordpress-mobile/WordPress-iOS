#!/bin/sh

# Log everything in this script to the Xcode build console
set -e

CREDENTIALS_FILE=~/.mobile-secrets/iOS/WPiOS/ScreenshotCredentials.swift
DESTINATION=$SOURCE_ROOT/WordPressScreenshotGeneration/ScreenshotCredentials.swift
TEMPLATE=$SOURCE_ROOT/WordPressScreenshotGeneration/ScreenshotCredentials-Template.swift

echo $CREDENTIALS_FILE
echo $DESTINATION

# If the file exists in mobile secrets, just copy it over. Otherwise, use a template.
if [ -f $CREDENTIALS_FILE ]; then
    echo "USING PRODUCTION"
    cp $CREDENTIALS_FILE $DESTINATION
else
    echo "USING TEMPLATE"
    cp $TEMPLATE $DESTINATION
fi

# Update the file-last-updated time to prevent build issues
touch $DESTINATION
