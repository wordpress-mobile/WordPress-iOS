#!/bin/bash -eu

# Update the matching .outputs.xcfilelist when changing this
DEST="$CONFIGURATION_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH"

# CocoaPods fetches Gutenberg in two possible ways: XCFramework and source.
#
# We check first for the XCFramework setup, falling back to source only if that is not there.
#
# Because the XCFramework location is in `PODS_XCFRAMEWORKS_BUILD_DIR`, it will only appear if CocoaPods use XCFrameworks.
# This makes the setup robust against having both a copy of the XCFramework and of the Gutenberg source code in the Pods folder.

# Update the matching .inputs.xcfilelist when changing these
XCFRAMEWORK_BUNDLE_ROOT="$PODS_XCFRAMEWORKS_BUILD_DIR/Gutenberg/Gutenberg.framework"
PODS_BUNDLE_ROOT="$PODS_ROOT/Gutenberg/bundle/ios"
LOCAL_BUNDLE="$PODS_ROOT/../../gutenberg-mobile/bundle/ios"

BUNDLE_FILE="$DEST/main.jsbundle"
BUNDLE_ASSETS="$DEST/assets/"

if [[ -d $XCFRAMEWORK_BUNDLE_ROOT ]]; then
  cp "$XCFRAMEWORK_BUNDLE_ROOT/App.js" "$BUNDLE_FILE"
  # It appears we don't need to copy the assets when working with the XCFramework
elif [[ -d $PODS_BUNDLE_ROOT ]]; then
  cp "$PODS_BUNDLE_ROOT/App.js" "$BUNDLE_FILE"
  cp -r "$PODS_BUNDLE_ROOT/assets" "$BUNDLE_ASSETS"
elif [[ -d $LOCAL_BUNDLE ]]; then
  echo "warning: Using local bundle."
  cp "$LOCAL_BUNDLE/App.js" "$BUNDLE_FILE"
  cp -r "$LOCAL_BUNDLE/assets" "$BUNDLE_ASSETS"
else
  if [[ "$CONFIGURATION" = *Debug* ]]; then
    echo "warning: Could not find Gutenberg bundle in either XCFramework or Pods. But running in Debug configuration so will assume you are working with a local version of Gutenberg."
  else
    echo "error: Could not find Gutenberg bundle in either XCFramework or Pods."
    exit 1
  fi
fi

if [[ "$CONFIGURATION" = *Debug* && ! "$PLATFORM_NAME" == *simulator ]]; then
  IP=$(ipconfig getifaddr en0)
  if [ -z "$IP" ]; then
    IP=$(ifconfig | grep 'inet ' | grep -v ' 127.' | cut -d\   -f2  | awk 'NR==1{print $1}')
  fi

  echo "$IP" > "$DEST/ip.txt"
fi
