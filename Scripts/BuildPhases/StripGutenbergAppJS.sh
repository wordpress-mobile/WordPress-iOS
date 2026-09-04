#!/bin/bash -eu

# Strips the redundant Gutenberg React Native JS bundle from the embedded
# Gutenberg.framework.
#
# The runtime loads the JS bundle from `main.jsbundle` at the app bundle root,
# placed there by the "Copy Gutenberg JS" phase. Gutenberg.framework also ships
# a byte-identical copy at `App.js` that is never loaded at runtime — ~7.7 MB of
# dead weight embedded into (and code-signed with) the app.
#
# We strip it from the *embedded* framework in the build products, never from
# the on-disk XCFramework, so local checkouts and other branches stay untouched
# regardless of configuration. We only remove it once the copy the runtime
# actually loads — main.jsbundle at the app root — is present, so we never
# delete the last copy (e.g. a Debug build served from a Metro dev server that
# produced no root bundle keeps the framework's App.js).
#
# Because the framework is code-signed on copy (CodeSignOnCopy), removing a
# sealed resource invalidates its signature, so we re-sign it afterwards. This
# phase runs after "Embed Frameworks" and before the app's final code signing.

FRAMEWORK="$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH/Gutenberg.framework"
APP_JS="$FRAMEWORK/App.js"

# Nothing to do if it's already gone (e.g. an incremental build that didn't
# re-embed the framework) or if the framework layout changed upstream.
if [[ ! -e "$APP_JS" ]]; then
  exit 0
fi

# Only strip the redundant framework copy when the copy the runtime loads —
# main.jsbundle at the app root, placed by "Copy Gutenberg JS" — is present, so
# we never delete the last copy of the bundle.
MAIN_BUNDLE="$CONFIGURATION_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/main.jsbundle"
if [[ ! -f "$MAIN_BUNDLE" ]]; then
  exit 0
fi

rm -f "$APP_JS"

# Re-sign the framework we just mutated, unless signing is disabled (e.g. a
# simulator build with CODE_SIGNING_ALLOWED=NO).
if [[ "${CODE_SIGNING_ALLOWED:-YES}" == "YES" && -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ]]; then
  codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" \
    --preserve-metadata=identifier,entitlements,flags \
    "$FRAMEWORK"
fi
