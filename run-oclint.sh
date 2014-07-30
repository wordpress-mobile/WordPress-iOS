#!/bin/sh

source ~/.bash_profile

hash oclint &> /dev/null
if [ $? -eq 1 ]; then
    echo >&2 "oclint not found, analyzing stopped"
    exit 1
fi

temp_dir="/tmp"
build_dir="${temp_dir}/WPiOS_linting"

echo "[*] cleaning up generated files"
if [ -f ${temp_dir}/compile_commands.json ]; then
    rm ${temp_dir}/compile_commands.json
fi
if [ -f ${temp_dir}/xcodebuild.log ]; then
    rm ${temp_dir}/xcodebuild.log
fi

echo "[*] starting xcodebuild to build the project.."

if [ -d WordPress.xcworkspace ]; then
    # we're running the script from the CLI
    xcode_workspace="WordPress.xcworkspace"
    additional_pipe=""
elif [ -d ../WordPress.xcworkspace ]; then
    # we're running the script from Xcode
    xcode_workspace="../WordPress.xcworkspace"
    additional_pipe="| sed 's/\\(.*\\.\\m\\{1,2\\}:[0-9]*:[0-9]*:\\)/\\1 warning:/'"
else
    # error!
    echo >&2 "workspace not found, analyzing stopped"
    exit 1
fi

xcodebuild -sdk "iphonesimulator7.1" \
           CONFIGURATION_BUILD_DIR=$build_dir \
           -workspace $xcode_workspace -configuration Debug -scheme WordPress clean build \
           DSTROOT=$build_dir OBJROOT=$build_dir SYMROOT=$build_dir \
           | tee ${temp_dir}/xcodebuild.log

echo "[*] transforming xcodebuild.log into compile_commands.json..."
cd ${temp_dir}
oclint-xcodebuild -e Pods/

echo "[*] starting analyzing"
if [ -d WordPress.xcworkspace ]; then
    # we're running the script from the CLI
    oclint-json-compilation-database -e Pods/ oclint_args "-rc LONG_LINE=120 SHORT_VARIABLE_NAME=1"
elif [ -d ../WordPress.xcworkspace ]; then
    # we're running the script from Xcode
    oclint-json-compilation-database -e Pods/ oclint_args "-rc LONG_LINE=120 SHORT_VARIABLE_NAME=1" | sed 's/\\(.*\\.\\m\\{1,2\\}:[0-9]*:[0-9]*:\\)/\\1 warning:/'
else
    # error!
    echo >&2 "workspace not found, analyzing stopped"
    exit 1
fi

rm -rf ${build_dir}
