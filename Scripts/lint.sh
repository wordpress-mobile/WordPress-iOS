#!/bin/sh

source "$(dirname $0)/common.inc"

if swiftlint_needs_install; then
  echo "SwiftLint ${SWIFTLINT_VERSION} not installed. Please run Scripts/install-swiftlint.sh"
  exit 1
fi

scripts_dir=$( dirname $0 )
project_dir="${scripts_dir}/../"

cd "$project_dir"

ARGS="--quiet"

if [[ "$CONFIGURATION" == "Release"* ]]; then
  ARGS="$ARGS --strict"
fi

$SWIFTLINT lint $ARGS
