#!/bin/bash

#  For details and documentation:
#  http://github.com/inkling/Subliminal
#
#  Copyright 2013-2014 Inkling Systems, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#


# `build.sh` builds `subliminal-instrument`,
# using the build output directory specified by `build_output_dir.sh`.


set -e

# Retrieve an absolute path to `subliminal-instrument`'s root directory,
# assuming that this script is inside a subdirectory thereof (i.e. "scripts")
SI_DIR=$(cd "$(dirname "$0")/.."; pwd)

BUILD_OUTPUT_DIR_TOOL_PATH="$SI_DIR"/scripts/build_output_dir.sh
BUILD_OUTPUT_DIR=$("$BUILD_OUTPUT_DIR_TOOL_PATH")

xcrun xcodebuild \
    -project "$SI_DIR"/subliminal-instrument.xcodeproj \
    -scheme subliminal-instrument \
    -configuration Release \
    -IDEBuildLocationStyle=Custom \
    -IDECustomBuildLocationType=Absolute \
    -IDECustomBuildProductsPath="$BUILD_OUTPUT_DIR/Products" \
    -IDECustomBuildIntermediatesPath="$BUILD_OUTPUT_DIR/Intermediates"

exit $?
