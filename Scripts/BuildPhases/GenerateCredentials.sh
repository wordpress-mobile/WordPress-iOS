#!/usr/bin/env bash

set -euo pipefail

# The committed .age blob is the versioned source of the decrypted secrets file.
# Where a8c-secrets puts the plaintext is the tool's business, so ask it rather
# than spelling out its layout here.
ENCRYPTED_SECRETS_FILE="${SRCROOT}/../.a8c-secrets/Secrets.swift.age"

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
  file_to_find=$1

  i=0
  found=false
  while [[ $i -lt $SCRIPT_INPUT_FILE_LIST_COUNT && "$found" = false ]]
  do
    # Need this two step process to access the input at index
    file_list_resolved_var_name=SCRIPT_INPUT_FILE_LIST_${i}
    # The following reads the processed xcfilelist line by line looking for
    # the given file
    while read input_file; do
      if [ "$file_to_find" == "$input_file" ]; then
        found=true
        break
      fi
    done <"${!file_list_resolved_var_name}"
    let i=i+1
  done
  if [ "$found" = false ]; then
    echo "error: Could not find $file_to_find as an input to the build phase. Add $file_to_find to the input files list using the .xcfilelist."
    exit 1
  fi
}

ensure_is_in_input_files_list $ENCRYPTED_SECRETS_FILE

LOCAL_SECRETS_FILE="${SRCROOT}/Credentials/Secrets.swift"
EXAMPLE_SECRETS_FILE="${SRCROOT}/Credentials/Secrets-example.swift"
ensure_is_in_input_files_list $EXAMPLE_SECRETS_FILE

# The Secrets file destination
SECRETS_DESTINATION_FILE="${SCRIPT_OUTPUT_FILE_0}"
mkdir -p "$(dirname "$SECRETS_DESTINATION_FILE")"

# Only rewrite the destination when the content changed: a checkout can bump an
# input's mtime without the secrets themselves changing, and an unconditional
# copy would then force a recompile of Secrets.swift.
function copy_if_changed() {
  cmp -s "$1" "$SECRETS_DESTINATION_FILE" || cp -v "$1" "$SECRETS_DESTINATION_FILE"
}

# `a8c-secrets which` exits non-zero when the file has not been decrypted yet.
# WordPress, Jetpack, and Reader use all the same secrets at this time.
if command -v a8c-secrets > /dev/null 2>&1 && SECRETS_FILE=$(a8c-secrets which Secrets.swift 2>/dev/null); then
    echo "Applying Production Secrets"
    copy_if_changed "$SECRETS_FILE"
    exit 0
fi

EXTERNAL_CONTRIBUTOR_RELEASE_MSG="External contributors should not need to perform a Release build"

# If the developer has a local secrets file, use it
if [ -f "$LOCAL_SECRETS_FILE" ]; then
    if [[ $CONFIGURATION == Release* ]]; then
      echo "error: You can't do a Release build when using local Secrets (from $LOCAL_SECRETS_FILE). $EXTERNAL_CONTRIBUTOR_RELEASE_MSG."
      exit 1
    fi

    echo "warning: Using local Secrets from $LOCAL_SECRETS_FILE. If you are an external contributor, this is expected and you can ignore this warning. If you are an internal contributor, make sure to use our shared credentials instead."
    echo "Applying Local Secrets"
    copy_if_changed "$LOCAL_SECRETS_FILE"
    exit 0
fi

# None of the above secrets was found. Use the example secrets file as a last
# resort, unless building for Release.

COULD_NOT_FIND_SECRET_MSG="Could not find secrets file at ${SECRETS_DESTINATION_FILE}. This is likely due to the secrets not having been decrypted"
INTERNAL_CONTRIBUTOR_MSG="If you are an internal contributor, run \`a8c-secrets decrypt\` to update your secrets and try again (see https://github.com/Automattic/a8c-secrets for setup)"
EXTERNAL_CONTRIBUTOR_MSG="If you are an external contributor, run \`bundle exec rake init:oss\` to set up and use your own credentials"

case $CONFIGURATION in
  Release*)
    # There are two release configurations: Release and Release-Alpha.
    # Since they all start with "Release", we can use a
    # pattern to check for them.
    echo "error: $COULD_NOT_FIND_SECRET_MSG. Cannot continue Release build. $INTERNAL_CONTRIBUTOR_MSG. $EXTERNAL_CONTRIBUTOR_RELEASE_MSG."
    exit 1
    ;;
  *)
    echo "warning: $COULD_NOT_FIND_SECRET_MSG. Falling back to $EXAMPLE_SECRETS_FILE. In a Release build, this would be an error. $INTERNAL_CONTRIBUTOR_MSG. $EXTERNAL_CONTRIBUTOR_MSG."
    echo "Applying Example Secrets"
    copy_if_changed "$EXAMPLE_SECRETS_FILE"
    ;;
esac
