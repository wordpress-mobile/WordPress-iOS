#!/bin/bash -eu

# Runs the localization tooling's pure-Ruby unit suites (stdlib minitest — no Xcode, no app build, no bundle).
# Intentionally always runs (no should-skip-job guard): these guard the fastlane localization helpers, and the
# `validation` skip rule skips on tooling-only changes — exactly when these tests matter most.

echo "--- :test_tube: Localization tooling unit tests"

shopt -s nullglob
tests=(fastlane/lanes/*_test.rb)
if [[ ${#tests[@]} -eq 0 ]]; then
  echo "No *_test.rb files found under fastlane/lanes/."
  exit 0
fi

status=0
for test in "${tests[@]}"; do
  echo "+++ :ruby: ${test}"
  ruby "${test}" || status=1
done

exit "${status}"
