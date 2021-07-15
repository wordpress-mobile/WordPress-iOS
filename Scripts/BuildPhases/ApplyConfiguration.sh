#!/bin/sh

set -e

# The Secrets File Sources
SECRETS_ROOT="${HOME}/.configure/wordpress-ios/secrets"

# To help the Xcode build system optimize the build, we want to ensure each of
# the secrets we want to copy is defined as an input file for the run script
# build phase.
#
# > The Xcode Build System will use [these files] to determine if your run
# > scripts should actually run or not. So this should include any file that
# > your run script phase, the script content, is actually going to read or
# > look at during its process.
#
# > If you have no input files declared, the Xcode build system will need to
# > run your run script phase on every single build.
#
# https://developer.apple.com/videos/play/wwdc2018/408/
function ensure_is_in_input_files_list() {
  # Loop through the file input lists looking for $1. If not found, fail the
  # build.
  if [ -z "$1" ]; then
    echo "error: Input file list verification needs a path to verify!"
    exit 1
  fi

  i=0
  found=false
  while [[ $i -lt $SCRIPT_INPUT_FILE_LIST_COUNT && "$found" = false ]]
  do
    # Need this two step process to access the input at index
    file_list_resolved_var_name=SCRIPT_INPUT_FILE_LIST_${i}
    # The following reads the processed xcfilelist line by line and
    while read input_file; do
      if [ "$1" == "$input_file" ]; then
        found=true
        break
      fi
    done <"${!file_list_resolved_var_name}"
    let i=i+1
  done
  if [ "$found" = false ]; then
    echo "error: Could not find $1 as an input to the build phase. Add $1 to the input files list using the .xcfilelist."
    exit 1
  fi
}

PRODUCTION_SECRETS_FILE="${SECRETS_ROOT}/WordPress-Secrets.swift"
ensure_is_in_input_files_list $PRODUCTION_SECRETS_FILE
INTERNAL_SECRETS_FILE="${SECRETS_ROOT}/WordPress-Secrets-Internal.swift"
ensure_is_in_input_files_list $INTERNAL_SECRETS_FILE
ALPHA_SECRETS_FILE="${SECRETS_ROOT}/WordPress-Secrets-Alpha.swift"
ensure_is_in_input_files_list $ALPHA_SECRETS_FILE
JETPACK_SECRETS_FILE="${SECRETS_ROOT}/Jetpack-Secrets.swift"
ensure_is_in_input_files_list $JETPACK_SECRETS_FILE

LOCAL_SECRETS_FILE="${SRCROOT}/Credentials/Secrets.swift"
EXAMPLE_SECRETS_FILE="${SRCROOT}/Credentials/Secrets-example.swift"
ensure_is_in_input_files_list $EXAMPLE_SECRETS_FILE

# The Secrets file destination
SECRETS_DESTINATION_FILE="${BUILD_DIR}/Secrets/Secrets.swift"
mkdir -p $(dirname "$SECRETS_DESTINATION_FILE")

# If the WordPress Production Secrets are available for WordPress, use them
if [ -f "$PRODUCTION_SECRETS_FILE" ] && [ "$BUILD_SCHEME" == "WordPress" ]; then
    echo "Applying Production Secrets"
    cp -v $PRODUCTION_SECRETS_FILE "${SECRETS_DESTINATION_FILE}"
    exit 0
fi

# If the WordPress Internal Secrets are available, use them
if [ -f "$INTERNAL_SECRETS_FILE" ] && [ "${BUILD_SCHEME}" == "WordPress Internal" ]; then
    echo "Applying Internal Secrets"
    cp -v $INTERNAL_SECRETS_FILE "${SECRETS_DESTINATION_FILE}"
    exit 0
fi

# If the WordPress Alpha Secrets are available, use them
if [ -f "$ALPHA_SECRETS_FILE" ] && [ "${BUILD_SCHEME}" == "WordPress Alpha" ]; then
    echo "Applying Alpha Secrets"
    cp -v $ALPHA_SECRETS_FILE "${SECRETS_DESTINATION_FILE}"
    exit 0
fi

# If the Jetpack Secrets are available (and if we're building Jetpack) use them
if [ -f "$JETPACK_SECRETS_FILE" ] && [ "${BUILD_SCHEME}" == "Jetpack" ]; then
    echo "Applying Jetpack Secrets"
    cp -v $JETPACK_SECRETS_FILE "${SECRETS_DESTINATION_FILE}"
    exit 0
fi

# If the developer has a local secrets file, use it
if [ -f "$LOCAL_SECRETS_FILE" ]; then
    echo "Applying Local Secrets"
    cp -v $LOCAL_SECRETS_FILE "${SECRETS_DESTINATION_FILE}"
    exit 0
fi

# None of the above secrets was found. Use the example secrets file as a last
# resort, unless building for Release.
case $CONFIGURATION in
  # There are three release configurations: Release, Release-Alpha, and
  # Release-Internal. Since they all start with "Release" we can use a pattern
  # to check for them.
  Release*)
    echo "error: Could not find secrets at $SECRETS_ROOT. Cannot continue release build."
    exit 1
    ;;
  *)
    echo "Applying Example Secrets"
    echo "warning: Could not find secrets at $SECRETS_ROOT, falling back to $EXAMPLE_SECRETS_FILE. In a release build, this would be an error."
    cp -v $EXAMPLE_SECRETS_FILE $SECRETS_DESTINATION_FILE
    ;;
esac
