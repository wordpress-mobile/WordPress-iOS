#!/bin/sh
source ~/.bash_profile

check_file="$1"
oclint_args="-rc LONG_LINE=120 -rc SHORT_VARIABLE_NAME=1 -rc LONG_METHOD=75"

hash oclint &> /dev/null
if [ $? -eq 1 ]; then
    echo >&2 "oclint not found, analyzing stopped"
    exit 1
fi

temp_dir="/tmp"
build_dir="${temp_dir}/WPiOS_linting"
compile_commands_path=${temp_dir}/compile_commands.json
xcodebuild_log_path=${temp_dir}/xcodebuild.log

echo "[*] cleaning up generated files"
[[ -f $compile_commands_path ]] && rm ${compile_commands_path}
[[ -f $xcodebuild_log_path ]] && rm ${xcodebuild_log_path}

echo "[*] starting xcodebuild to build the project.."
if [ -d WordPress.xcworkspace ]; then
    # we're running the script from the CLI
    xcode_workspace="WordPress.xcworkspace"
    pipe_command=""
elif [ -d ../WordPress.xcworkspace ]; then
    # we're running the script from Xcode
    xcode_workspace="../WordPress.xcworkspace"
    pipe_command="| sed 's/\\(.*\\.\\m\\{1,2\\}:[0-9]*:[0-9]*:\\)/\\1 warning:/'"
else
    # error!
    echo >&2 "workspace not found, analyzing stopped"
    exit 1
fi

xcodebuild -sdk "iphonesimulator7.1" \
           CONFIGURATION_BUILD_DIR=$build_dir \
           -workspace $xcode_workspace -configuration Debug -scheme WordPress clean build \
           DSTROOT=$build_dir OBJROOT=$build_dir SYMROOT=$build_dir \
           | tee ${xcodebuild_log_path}

echo "[*] transforming xcodebuild.log into compile_commands.json..."
cd ${temp_dir}
oclint-xcodebuild -e Pods/ -o ${compile_commands_path}

echo "[*] starting analyzing"

if [ $check_file ]; then
    include_files="-i $check_file"
    exclude_files="-e *"
else
    include_files=""
    exclude_files="-e Pods/ -e Vendor/"
fi

eval "oclint-json-compilation-database $exclude_files oclint_args \"$oclint_args\" $include_files $pipe_command"
exit 0
