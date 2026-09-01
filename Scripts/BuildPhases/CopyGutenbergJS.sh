#!/bin/bash -eu

# Update the matching .outputs.xcfilelist when changing this
DEST="$CONFIGURATION_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH"

# Update the matching .inputs.xcfilelist when changing these
#
# The React Native runtime loads the JS bundle from main.jsbundle at the app
# bundle root, so we copy the prebuilt bundle there. We read it from the
# standalone copy that ships alongside the XCFramework rather than from
# Gutenberg.framework/App.js: that in-framework copy is byte-identical and is
# stripped by download-gutenberg-xcframeworks.sh so it isn't embedded twice.
DOWNLOADED_JS_BUNDLE="$SRCROOT/Frameworks/react-native-bundle-source-map/main.jsbundle"
LOCAL_BUNDLE="$SRCROOT/../gutenberg-mobile/bundle/ios"

BUNDLE_FILE="$DEST/main.jsbundle"
BUNDLE_ASSETS="$DEST/assets/"

if [[ -f $DOWNLOADED_JS_BUNDLE ]]; then
  cp "$DOWNLOADED_JS_BUNDLE" "$BUNDLE_FILE"
  # It appears we don't need to copy the assets when working with the XCFramework
elif [[ -d $LOCAL_BUNDLE ]]; then
  echo "warning: Using local bundle."
  cp "$LOCAL_BUNDLE/App.js" "$BUNDLE_FILE"
  cp -r "$LOCAL_BUNDLE/assets" "$BUNDLE_ASSETS"
else
  if [[ "$CONFIGURATION" = *Debug* ]]; then
    echo "warning: Could not find Gutenberg bundle in the XCFramework. But running in Debug configuration so will assume you are working with a local version of Gutenberg."
  else
    echo "error: Could not find Gutenberg bundle in XCFramework."
    exit 1
  fi
fi

if [[ "$CONFIGURATION" = *Debug* && ! "$PLATFORM_NAME" == *simulator ]]; then
  IP=$(ipconfig getifaddr en0 || echo "")
  if [ -z "$IP" ]; then
    IP=$(ifconfig | grep 'inet ' | grep -v ' 127.' | cut -d\   -f2  | awk 'NR==1{print $1}')
  fi

  echo "$IP" > "$DEST/ip.txt"
fi
