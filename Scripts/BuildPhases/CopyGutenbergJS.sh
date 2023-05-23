#!/bin/bash -eu

# Update the matching .outputs.xcfilelist when changing this
DEST="$CONFIGURATION_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH"

# CocoaPods fetches Gutenberg in two possible ways: XCFramework and source.
#
# We check first for the XCFramework setup, fallingback to source only if that is not there.
#
# Because the XCFramework location is in `PODS_XCFRAMEWORKS_BUILD_DIR`, it will only appear if CocoaPods use XCFrameworks.
# This makes the setup robust against having both a copy of the XCFramework and of the Gutenberg source code in the Pods folder.

# Update the matching .inputs.xcfilelist when changing these
XCFRAMEWORK_BUNDLE_ROOT="$PODS_XCFRAMEWORKS_BUILD_DIR/Gutenberg/Gutenberg.framework"
PODS_BUNDLE_ROOT="$PODS_ROOT/Gutenberg/bundle/ios"

BUNDLE_FILE="$DEST/main.jsbundle"
BUNDLE_ASSETS="$DEST/assets/"

if [[ -d $XCFRAMEWORK_BUNDLE_ROOT ]]; then
  cp "$XCFRAMEWORK_BUNDLE_ROOT/App.js" "$BUNDLE_FILE"
  # It appears we don't need to copy the assets when working with the XCFramework
elif [[ -d $PODS_BUNDLE_ROOT ]]; then
  cp "$PODS_BUNDLE_ROOT/App.js" "$BUNDLE_FILE"
  cp -r "$PODS_BUNDLE_ROOT/assets" "$BUNDLE_ASSETS"
else
  echo "error: Could not find Gutenberg bundle in either XCFramework or Pods."
  exit 1
fi

if [[ "$CONFIGURATION" = *Debug* && ! "$PLATFORM_NAME" == *simulator ]]; then
  IP=$(ipconfig getifaddr en0)
  if [ -z "$IP" ]; then
    IP=$(ifconfig | grep 'inet ' | grep -v ' 127.' | cut -d\   -f2  | awk 'NR==1{print $1}')
  fi

  echo "$IP" > "$DEST/ip.txt"
fi
