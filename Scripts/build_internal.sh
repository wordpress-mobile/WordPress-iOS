if [ ! $TRAVIS ]; then
	TRAVIS_XCODE_WORKSPACE=WordPress.xcworkspace
	TRAVIS_XCODE_SCHEME="WordPress Internal"
    TRAVIS_XCODE_SDK=iphoneos8.4
    # Set environment
	source ~/.wpcom_internal_app_credentials
    pod install
fi

ARCHIVE_NAME="WordPressInternal"
PROVISIONING_PROFILE="WordPress Internal Distribution"
DEVELOPER_NAME="iPhone Distribution: Automattic, Inc."
GIT_VERSION=`git show --abbrev-commit | grep '^commit' | sed 's/commit //' | tr -d '\n'`
BUILD_PATH="build"
RELEASE_NOTES=`cat RELEASE_NOTES.md`

# Delete previous build 
rm -Rf "$BUILD_PATH"

#Build the archive
xcodebuild archive \
	-workspace "$TRAVIS_XCODE_WORKSPACE" \
	-scheme "$TRAVIS_XCODE_SCHEME" \
	-sdk "$TRAVIS_XCODE_SDK" \
	-archivePath "$BUILD_PATH/$ARCHIVE_NAME" \
	-derivedDataPath "$BUILD_PATH" \
	| xcpretty -c

# Then export it to an IPA
xcodebuild -exportArchive \
	-archivePath "$BUILD_PATH/$ARCHIVE_NAME.xcarchive" \
	-exportPath "$BUILD_PATH/$ARCHIVE_NAME" \
	-exportFormat ipa \
    -exportProvisioningProfile "$PROVISIONING_PROFILE" \
	# -exportSigningIdentity "$DEVELOPER_NAME"

# Zip the dSYM folder
zip -r $BUILD_PATH/$ARCHIVE_NAME.dSYM.zip "$BUILD_PATH/Build/Intermediates/ArchiveIntermediates/WordPress Internal/BuildProductsPath/Release-Internal-iphoneos/WordPress.app.dSYM"

#Upload to Hockey app
if [ -z "$HOCKEYAPP_API_TOKEN" ]
then
    echo "usage: you need to have defined the HOCKEYAPP_API_TOKEN enviroment variable in order to upload to HockeyApp your build"
    echo "run this in your command line: export HOCKEYAPP_API_TOKEN=xxxxxxxxxxxxxxxxxx"
    echo "with the appropiated key value" 
    exit 1
fi

curl --verbose \
  -F "status=1" \
  -F "notify=0" \
  -F "notes=$RELEASE_NOTES" \
  -F "notes_type=1" \
  -F "commit_sha=$GIT_VERSION" \
  -F "repository_url=https://github.com/wordpress-mobile/WordPress-iOS" \
  -F "ipa=@$BUILD_PATH/$ARCHIVE_NAME.ipa" \
  -F "dsym=@$BUILD_PATH/$ARCHIVE_NAME.dSYM.zip" \
  -H "X-HockeyAppToken: $HOCKEYAPP_API_TOKEN" \
  https://rink.hockeyapp.net/api/2/apps/$HOCKEYAPP_APP_ID/app_versions/upload
