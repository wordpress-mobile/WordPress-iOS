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


# `build_output_dir.sh` echoes the directory in which
# `subliminal-instrument`'s build output can be found.


# Retrieve an absolute path to `subliminal-instrument`'s root directory,
# assuming that this script is inside a subdirectory thereof (i.e. "scripts")
SI_DIR=$(cd "$(dirname "$0")/.."; pwd)

# Retrieve an absolute path to Subliminal's root directory,
# assuming that `subliminal-instrument` resides at $SL_DIR/Supporting Files/CI/subliminal-instrument)
SL_DIR=$(cd "$SI_DIR/../../../"; pwd)

# Will be a short git hash or just '.' if we're not in a git repo.
REVISION=$(\
    (git --git-dir="$SL_DIR/.git" log -n 1 --format=%h 2> /dev/null) ||\
    echo "."\
)

# if we're in a git repo, figure out if any changes have been made
# to `subliminal-instrument` inside that repo
if [[ "$REVISION" != "." ]]; then
    SI_RELATIVE_DIR=${SI_DIR#$SL_DIR/}
    NUM_CHANGES=$(git status --porcelain "$SL_DIR" | grep "$SI_RELATIVE_DIR" | wc -l)
    HAS_CHANGES=$([[ $NUM_CHANGES -gt 0 ]] && echo YES || echo NO)
else
    HAS_CHANGES=UNKNOWN
fi

BUILD_OUTPUT_DIR="$SI_DIR"/build/$REVISION
if [[ $HAS_CHANGES == "YES" ]]; then
    BUILD_OUTPUT_DIR="$BUILD_OUTPUT_DIR"-dirty
fi

echo "$BUILD_OUTPUT_DIR"
