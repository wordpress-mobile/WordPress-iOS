#!/bin/bash -euo pipefail

export PATH="$PATH:/opt/homebrew/bin"

if [ -f /opt/homebrew/bin/swift-package-list ]; then
    echo "Running swift-package-list to generate package list"

    OUTPUT_PATH="$DERIVED_FILE_DIR/package-list.json"
    PROJECT_ROOT=$(dirname $SRCROOT)
    echo "swift-package-list: $PROJECT_ROOT"

    WORKSPACE_FILE_PATH="$PROJECT_ROOT/WordPress.xcworkspace"

    echo "swift-package-list: $WORKSPACE_FILE_PATH"
    echo "swift-package-list: $OUTPUT_PATH"

    swift-package-list "$WORKSPACE_FILE_PATH" --requires-license | tee "$OUTPUT_PATH"
    cp "$OUTPUT_PATH" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/package-list.json"
    echo "swift-package-list: ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/package-list.json"

    echo "swift-package-list: Generation Complete"
else
    echo "warning: swift-package-list not installed. Run \`brew tap FelixHerrmann/tap && brew install swift-package-list\` to install it."
fi
