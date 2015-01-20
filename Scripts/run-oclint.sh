#!/bin/sh
source ~/.bash_profile

check_file="$1"
oclint_args="-disable-rule=ShortVariableName -disable-rule=LongLine -rc LONG_LINE=300 -rc SHORT_VARIABLE_NAME=1 -rc LONG_METHOD=75 -rc LONG_VARIABLE_NAME=40"
temp_dir="/tmp"
build_dir="${temp_dir}/WPiOS_linting"
compile_commands_path=${temp_dir}/compile_commands.json
xcodebuild_log_path=${temp_dir}/xcodebuild.log

if [ "${TRAVIS}" = "true" ]; then
  echo "[*] installing travis"
  pushd .
  cd ${temp_dir}
  curl http://archives.oclint.org/releases/0.8/oclint-0.8.1-x86_64-darwin-14.0.0.tar.gz > oclint.tar.gz
  tar -zxvf oclint.tar.gz
  OCLINT_HOME=${temp_dir}/oclint-0.8.1
  export PATH=$OCLINT_HOME/bin:$PATH
  popd
fi

hash oclint &> /dev/null
if [ $? -eq 1 ]; then
    echo >&2 "oclint not found, analyzing stopped"
    exit 1
fi

oclint --version
xctool --version
xcodebuild -version

echo "[*] cleaning up generated files"
[[ -f $compile_commands_path ]] && rm ${compile_commands_path}
[[ -f $xcodebuild_log_path ]] && rm ${xcodebuild_log_path}

echo "[*] starting xcodebuild to build the project.."
if [ -d WordPress.xcworkspace ]; then
    echo "[*] we're running the script from the CLI"
    xcode_workspace="WordPress.xcworkspace"
    pipe_command=""
elif [ -d ../WordPress.xcworkspace ]; then
    echo "[*] we're running the script from Xcode"
    xcode_workspace="../WordPress.xcworkspace"
    pipe_command="| sed 's/\\(.*\\.\\m\\{1,2\\}:[0-9]*:[0-9]*:\\)/\\1 warning:/'"
else
    # error!
    echo >&2 "workspace not found, analyzing stopped"
    exit 1
fi

echo "[*] Cleaning project"
xctool clean \
           -sdk "iphonesimulator8.1" \
           CONFIGURATION_BUILD_DIR=$build_dir \
           -workspace $xcode_workspace -configuration Debug -scheme WordPress

echo "[*] Building project"
xctool build \
           -sdk "iphonesimulator8.1" \
           CONFIGURATION_BUILD_DIR=$build_dir \
           -derivedDataPath=$build_dir \
           -workspace $xcode_workspace -configuration Debug -scheme WordPress \
           DSTROOT=$build_dir OBJROOT=$build_dir SYMROOT=$build_dir \
           -reporter json-compilation-database:$compile_commands_path

#echo "[*] transforming xcodebuild.log into compile_commands.json..."
cd ${temp_dir}
#oclint-xcodebuild -e Pods/ -o ${compile_commands_path}

echo "[*] starting analyzing"

if [ $check_file ]; then
    echo "[*] Single Files $check_file";
    include_files="-i $check_file"
    exclude_files="-e *"
else
    echo "[*] All project files";
    include_files=""
    exclude_files="-e Pods/ -e Vendor/ -e WordPressTodayWidget/"
fi

eval "oclint-json-compilation-database -v $exclude_files oclint_args \"$oclint_args\" $include_files $pipe_command"
exit 0
