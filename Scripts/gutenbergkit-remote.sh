#!/bin/bash
#
# Disable local GutenbergKit development by switching Package.swift back to remote.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PACKAGE_SWIFT="$REPO_ROOT/Modules/Package.swift"
JETPACK_SCHEME="$REPO_ROOT/WordPress/WordPress.xcodeproj/xcshareddata/xcschemes/Jetpack.xcscheme"

# Extract the GutenbergKit version from trunk
VERSION=$(git show trunk:Modules/Package.swift \
    | grep 'wordpress-mobile/GutenbergKit' \
    | sed -n 's/.*from: "\([^"]*\)".*/\1/p')

if [ -z "$VERSION" ]; then
    echo "Error: Could not find GutenbergKit version in git history" >&2
    exit 1
fi

# Replace local path with remote URL
sed -i '' "s|\.package(path: \"../../GutenbergKit\")|.package(url: \"https://github.com/wordpress-mobile/GutenbergKit\", from: \"$VERSION\")|" "$PACKAGE_SWIFT"

# Disable GUTENBERG_EDITOR_URL environment variable in Jetpack scheme
sed -i '' '
    /key = "GUTENBERG_EDITOR_URL"/{
        n
        n
        s/isEnabled = "YES"/isEnabled = "NO"/
    }
' "$JETPACK_SCHEME"

echo "Switched to remote GutenbergKit ($VERSION)"
echo "Disabled GUTENBERG_EDITOR_URL in Jetpack scheme"
echo "Resolving package dependencies..."

xcodebuild -resolvePackageDependencies -project "$REPO_ROOT/WordPress/WordPress.xcodeproj" -quiet

echo "Done"
