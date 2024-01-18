#!/bin/bash -u

echo "--- :swift: Running SwiftLint"

# Using --strict to fail the build and increase the likelyhood devs will notice the violations
swiftlint_output=$(swiftlint lint --quiet --strict --reporter csv)
swiftlint_exit_status=$?

# TODO: It's likely that using --strict will result in all violations being errors
warnings=$(echo "$swiftlint_output" | awk -F',' '$4=="Warning" {print "- `"$1":"$2"`: "$6}')
errors=$(echo "$swiftlint_output" | awk -F',' '$4=="Error" {print "- `"$1":"$2"`: "$6}')

if [ -n "$warnings" ]; then
  echo "$warnings"
  printf '**SwiftLint Warnings**\n%b' "$warnings" | buildkite-agent annotate --style 'warning'
fi

if [ -n "$errors" ]; then
  echo "$errors"
  printf '**SwiftLint Errors**\n%b' "$errors" | buildkite-agent annotate --style 'error'
fi

exit $swiftlint_exit_status
