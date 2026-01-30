#!/bin/bash
#
# Enable local GutenbergKit development by switching Package.swift to use a local path.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PACKAGE_SWIFT="$REPO_ROOT/Modules/Package.swift"
JETPACK_SCHEME="$REPO_ROOT/WordPress/WordPress.xcodeproj/xcshareddata/xcschemes/Jetpack.xcscheme"

# Check if already using local path
if grep -q '\.package(path: "../../GutenbergKit")' "$PACKAGE_SWIFT"; then
    echo "Already using local GutenbergKit path"
    exit 0
fi

# Verify remote URL exists before replacing
if ! grep -q 'github.com/wordpress-mobile/GutenbergKit' "$PACKAGE_SWIFT"; then
    echo "Error: Could not find GutenbergKit dependency in Package.swift" >&2
    exit 1
fi

# Replace GutenbergKit dependency with local path
sed -i '' 's|\.package(url: "https://github.com/wordpress-mobile/GutenbergKit",[^)]*)|.package(path: "../../GutenbergKit")|' "$PACKAGE_SWIFT"

# Verify the change was applied
if ! grep -q '\.package(path: "../../GutenbergKit")' "$PACKAGE_SWIFT"; then
    echo "Error: Failed to update Package.swift" >&2
    exit 1
fi

# Enable GUTENBERG_EDITOR_URL environment variable in Jetpack scheme
sed -i '' '
    /key = "GUTENBERG_EDITOR_URL"/{
        n
        n
        s/isEnabled = "NO"/isEnabled = "YES"/
    }
' "$JETPACK_SCHEME"

echo "Switched to local GutenbergKit path"
echo "Enabled GUTENBERG_EDITOR_URL in Jetpack scheme"
echo "Resolving package dependencies (this may take a while)..."

xcodebuild -resolvePackageDependencies -project "$REPO_ROOT/WordPress/WordPress.xcodeproj" -quiet

echo "Done"
