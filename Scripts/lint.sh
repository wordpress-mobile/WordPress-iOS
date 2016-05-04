#!/bin/sh

if ! which swiftlint >/dev/null; then
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint or `brew install swiftlint`"
fi

scripts_dir=$( dirname $0 )
project_dir="${scripts_dir}/../"

cd "$project_dir"

swiftlint lint $*
