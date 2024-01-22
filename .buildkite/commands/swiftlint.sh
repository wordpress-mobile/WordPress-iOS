#!/bin/bash -u

echo "--- :swift: Running SwiftLint"

set +e
SWIFTLINT_OUTPUT=$(swiftlint lint --quiet "$@" --reporter relative-path)
SWIFTLINT_EXIT_STATUS=$?
set -e

WARNINGS=$(echo -e "$SWIFTLINT_OUTPUT" | awk -F': ' '/: warning:/ {printf "- `%s`: %s\n", $1, $4}')
ERRORS=$(echo -e "$SWIFTLINT_OUTPUT" | awk -F': ' '/: error:/ {printf "- `%s`: %s\n", $1, $4}')

if [ -n "$WARNINGS" ]; then
  echo "$WARNINGS"
  printf "**SwiftLint Warnings**\n%b" "$WARNINGS" | buildkite-agent annotate --style 'warning'
fi

if [ -n "$ERRORS" ]; then
  echo "$ERRORS"
  printf "**SwiftLint Errors**\n%b" "$ERRORS" | buildkite-agent annotate --style 'error'
fi

exit $SWIFTLINT_EXIT_STATUS
