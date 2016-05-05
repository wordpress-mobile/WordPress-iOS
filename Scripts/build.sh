#!/bin/sh

set -o pipefail

if [ $TRAVIS ]; then
  XCODE_WORKSPACE=$TRAVIS_XCODE_WORKSPACE
  XCODE_SCHEME=$TRAVIS_XCODE_SCHEME
  XCODE_SDK=$TRAVIS_XCODE_SDK
else
  XCODE_WORKSPACE=WordPress.xcworkspace
  XCODE_SCHEME=WordPress
  XCODE_SDK=iphonesimulator
fi

function xcbuild() {
xcodebuild \
  -destination "platform=iOS Simulator,name=iPhone 6s" \
  -workspace "$XCODE_WORKSPACE" \
  -scheme "$XCODE_SCHEME" \
  -sdk "$XCODE_SDK" \
  -configuration Debug \
  $*
}

function build() {
  xcbuild build test
}

function clean_build() {
  xcbuild clean build test
}

function pretty_travis() {
  xcpretty -c
}

function rawlog() {
  tee $1
}

function usage() {
  cat <<EOF
Usage: $0 [-cdhv] [-l logfile]
  -c  Force clean before building.
  -d  Debug. Shows commands before running them.
  -l  Store raw build log in the specified file.
  -v  Verbose. Skips xcpretty.
  -h  Show this message.
EOF
}

CLEAN=0
DEBUG=0
LOGFILE=""
VERBOSE=0
while getopts ":cdhl:v" opt; do
  case $opt in
    c)
      CLEAN=1
      ;;
    d)
      DEBUG=1
      ;;
    h)
      usage
      exit 0
      ;;
    l)
      LOGFILE=$OPTARG
      ;;
    v)
      VERBOSE=1
      ;;
    :)
      echo "ERROR: -$OPTARG requires an argument" >&2
      exit 1
  esac
done

BUILD_CMD=build
if [ $CLEAN == 1 ]; then
  BUILD_CMD=clean_build
fi

CMD="$BUILD_CMD"

if [ "$LOGFILE" != "" ]; then
  CMD="$CMD | rawlog $LOGFILE"
fi

if [ $VERBOSE == 0 ]; then
  CMD="$CMD | pretty_travis"
fi

if [ $DEBUG == 1 ]; then
  echo $CMD
  set -x
fi

$CMD

