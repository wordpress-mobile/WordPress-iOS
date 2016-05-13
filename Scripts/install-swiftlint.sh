#!/bin/bash

# Installs the SwiftLint package.

source "$(dirname $0)/common.inc"

# Exit immediately if any command fails
set -e

# Print commands before running them
#set -x

TMPDIR=$(mktemp -d /tmp/Swiftlint.build.XXXX)

if ! swiftlint_needs_install;then
  echo "Swiftlint $SWIFTLINT_VERSION already installed"
  exit 0
fi

echo "Installing SwiftLint $SWIFTLINT_VERSION into $SWIFTLINT_PREFIX"

git clone --branch $SWIFTLINT_VERSION https://github.com/realm/SwiftLint.git $TMPDIR
cd $TMPDIR
git submodule update --init --recursive

rm -rf $SWIFTLINT_PREFIX
mkdir -p $SWIFTLINT_PREFIX
make prefix_install PREFIX="$SWIFTLINT_PREFIX"

rm -rf $TMPDIR

