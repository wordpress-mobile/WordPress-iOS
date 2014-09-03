#!/bin/sh

#  For details and documentation:
#  http://github.com/inkling/Subliminal
#
#  Copyright 2014 Inkling Systems, Inc.
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

#  `watchdog.sh` launches a process (the "child" process) and monitors both it
#  and the parent process. If the parent process has died, `watchdog.sh` terminates
#  the child process and any subprocesses thereof, then aborts.
#
#  Usage: watchdog.sh <parent_pid> <watch_interval>
#
#  Arguments:
#   parent_pid      The pid of the parent process.
#   watch_interval  The interval, in seconds (an integer) at which to check
#                   whether the parent and child are still alive.
#

PARENT_PID=$1
WATCH_INTERVAL=$2

# Launch the child
"${@:3}" &
CHILD_PID=$!

# Abort if we failed to launch the child
# The tiny delay allows it to exit
sleep 0.1
if ! kill -0 $CHILD_PID 2> /dev/null; then exit 1; fi

# Monitor the parent and child
while kill -0 $PARENT_PID 2> /dev/null && kill -0 $CHILD_PID 2> /dev/null; do
    sleep $WATCH_INTERVAL
done

# Kill the child in case the parent aborted
kill -9 $CHILD_PID 2> /dev/null

# Also kill any subprocesses of the child
for child in $(ps -o pid,ppid -ax 2> /dev/null | \
    awk "{ if ( \$2 == $CHILD_PID ) { print \$1 }}")
do
    kill -9 $child
done

exit 0
