#!/bin/sh

if ! which swiftlint >/dev/null; then
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint or 'brew install swiftlint'"
  exit 0
fi

scripts_dir=$( dirname $0 )
project_dir="${scripts_dir}/../"

cd "$project_dir"

ARGS="--quiet"

if [[ "$CONFIGURATION" == "Release"* ]]; then
  ARGS="$ARGS --strict"
fi

swiftlint lint $ARGS
