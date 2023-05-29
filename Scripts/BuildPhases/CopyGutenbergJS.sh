#!/bin/bash -eux

# Update the matching .outputs.xcfilelist when changing this
DEST=$CONFIGURATION_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH

if [[ "$CONFIGURATION" = *Debug* && ! "$PLATFORM_NAME" == *simulator ]]; then
  IP=$(ipconfig getifaddr en0)
  if [ -z "$IP" ]; then
    IP=$(ifconfig | grep 'inet ' | grep -v ' 127.' | cut -d\   -f2  | awk 'NR==1{print $1}')
  fi

  echo "$IP" > "$DEST/ip.txt"
fi

# Update the matching .inputs.xcfilelist when changing this
PODS_BUNDLE_ROOT="$PODS_ROOT/Gutenberg/bundle/ios"

BUNDLE_FILE="$DEST/main.jsbundle"
cp "$PODS_BUNDLE_ROOT/App.js" "$BUNDLE_FILE"

BUNDLE_ASSETS="$DEST/assets/"
cp -r "$PODS_BUNDLE_ROOT/assets/" "$BUNDLE_ASSETS"
