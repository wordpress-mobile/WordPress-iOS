#!/bin/sh

if ! which swiftlint >/dev/null; then
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint or `brew install swiftlint`"
fi

scripts_dir=$( dirname $0 )
project_dir=$( cd ${scripts_dir}/../; pwd )
source_dir="${project_dir}/WordPress"

cd "$project_dir"

swiftlint lint $*
