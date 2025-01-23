#!/bin/bash -e

# Do not run in CI environments.
# Our CI has its own static linter.
# As of 2025/01, this should save some 20-40s per build.
if [ -n "${CI+x}" ]; then
  echo 'CI environment detected. Skipping SwiftLint build phase in favor of dedicated CI process.'
  exit 0
fi

rake lint
