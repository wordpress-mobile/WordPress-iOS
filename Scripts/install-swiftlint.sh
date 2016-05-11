#!/bin/bash

# Installs the SwiftLint package.

set -e

SWIFTLINT_VERSION="0.10.0"
SWIFTLINT_PKG_PATH="/tmp/SwiftLint.pkg"
SWIFTLINT_PKG_URL="https://github.com/realm/SwiftLint/releases/download/${SWIFTLINT_VERSION}/SwiftLint.pkg"

curl -L -o $SWIFTLINT_PKG_PATH $SWIFTLINT_PKG_URL

if [ -f $SWIFTLINT_PKG_PATH ]; then
  echo "SwiftLint package exists! Installing it..."
  sudo installer -pkg $SWIFTLINT_PKG_PATH -target /
else
  echo "error: SwiftLint package doesn't exist"
  exit 1
fi
