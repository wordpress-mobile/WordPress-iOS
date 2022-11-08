#!/bin/bash -eu

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- :writing_hand: Copy Files"
mkdir -pv ~/.configure/wordpress-ios/secrets
cp -v fastlane/env/project.env-example ~/.configure/wordpress-ios/secrets/project.env

echo "--- Lint Localized Strings Format"
LOGS=logs.txt
set +e
set -o pipefail
bundle exec fastlane generate_strings_file_for_glotpress skip_commit:true | tee $LOGS
EXIT_CODE=$?
set -e

echo $EXIT_CODE

if [[ $EXIT_CODE -ne 0 ]]; then
  # Strings generation finished with errors, extract the errors in an easy-to-find section
  echo "--- Report genstrings errors"
  ERRORS=errors.txt
  echo "Found errors when trying to run \`genstrings\` to generate the \`.strings\` files from \`*LocalizedStrings\` calls:" | tee $ERRORS
  echo '' >> $ERRORS
  # Print the errors inline.
  #
  # Notice the second `sed` call that removes the ANSI escape sequences that
  # Fastlane uses to color the output.
  grep -e "\[.*\].*genstrings:" $LOGS \
    | sed -e 's/\[.*\].*genstrings: error: /- /' \
    | sed -e $'s/\x1b\[[0-9;]*m//g' \
    | sort \
    | uniq \
    | tee -a $ERRORS
  # Annotate the build with the errors
  cat $ERRORS | buildkite-agent annotate --style error --context genstrings
fi

exit $EXIT_CODE
