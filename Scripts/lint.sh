#!/bin/sh

source "$(dirname $0)/common.inc"

if swiftlint_needs_install; then
  echo "SwiftLint ${SWIFTLINT_VERSION} not installed. Please run Scripts/install-swiftlint.sh"
  exit 1
fi

ARGS="--quiet"

if [[ "$CONFIGURATION" == "Release"* ]]; then
  ARGS="$ARGS --strict"
fi

$SWIFTLINT lint $ARGS | swiftlint_fix_location
