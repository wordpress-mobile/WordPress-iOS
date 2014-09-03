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


# `subliminal-instrument.sh` builds `subliminal-instrument` if necessary,
# then invokes the built executable with the arguments to this script.
# 
# This removes the need for `subliminal-instrument` to either be built during
# Subliminal's installation or to be checked into the repository as a compiled
# binary.
#
# `subliminal-instrument.sh` is modeled after a similar script in https://github.com/facebook/xctool.


set -e

# Retrieve the relative path to this script, even if invoked through a symlink
REALPATH=$([[ -L "$0" ]] && echo $(dirname "$0")/$(readlink "$0") || echo $0)

# Retrieve the absolute path to `subliminal-instrument`'s root directory,
# assuming that this script is inside a subdirectory thereof (i.e. "scripts")
SI_DIR=$(cd "$(dirname "$REALPATH")/.."; pwd)

BUILD_NEEDED_TOOL_PATH="$SI_DIR"/scripts/build_needed.sh
BUILD_NEEDED=$("$BUILD_NEEDED_TOOL_PATH")

# Build `subliminal-instrument if needed (silently, unless we fail)
if [ "$BUILD_NEEDED" -eq 1 ]; then
    BUILD_LOG=$(mktemp -t si-build)
    trap "rm -f $BUILD_LOG" SIGINT SIGTERM EXIT

    if ! "$SI_DIR"/scripts/build.sh > $BUILD_LOG 2>&1; then
        COLOR_BOLD_RED="\033[1;31m"
        COLOR_NORMAL="\033[0m"
        echo -e "${COLOR_BOLD_RED}ERROR${COLOR_NORMAL}: Failed to build \`subliminal-instrument\`:"
        cat $BUILD_LOG
        exit 1
    fi
fi

BUILD_OUTPUT_DIR_TOOL_PATH="$SI_DIR"/scripts/build_output_dir.sh
BUILD_OUTPUT_DIR=$("$BUILD_OUTPUT_DIR_TOOL_PATH")
SI_PATH="$BUILD_OUTPUT_DIR"/Products/Release/subliminal-instrument

WATCHDOG_TOOL_PATH="$SI_DIR"/scripts/watchdog.sh

# Launch `subliminal-instrument`, watched at a 1 second interval
# so that it will exit if/when this script is killed
"$WATCHDOG_TOOL_PATH" $$ 1 "$SI_PATH" "$@"
