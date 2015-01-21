#!/bin/sh
source ~/.bash_profile

oclint_args="-disable-rule=ShortVariableName -disable-rule=LongLine -disable-rule=LongClass -disable-rule=LongMethod -disable-rule=UnusedMethodParameter"
temp_dir="/tmp"
build_dir="${temp_dir}/WPiOS_linting"
compile_commands_path=${temp_dir}/compile_commands.json
xcodebuild_log_path=${temp_dir}/xcodebuild.log

if [ "${TRAVIS}" = "true" ]; then
  echo "[*] installing oclint 0.8.1"
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
           -workspace $xcode_workspace -configuration Debug -scheme WordPress \
           DSTROOT=$build_dir OBJROOT=$build_dir SYMROOT=$build_dir \
           -reporter json-compilation-database:$compile_commands_path

if [ $TRAVIS ]; then
    echo "[*] Only files changed on push";    
    include_files=`git diff $TRAVIS_COMMIT_RANGE --name-only | grep '\.m' | tr '\n' ' -i '`
    exclude_files="-e Pods/ -e Vendor/ -e WordPressTodayWidget/ -e SFHFKeychainUtils.m -e Constants.m"
    base_commit=`echo $TRAVIS_COMMIT_RANGE | cut -d '.' -f 1`
    base_commit+="^"
    if [ ! -z "$include_files" ]; then
      include_files="-i "$include_files      
    else
      exclude_files="-e *"
    fi
    echo "[*] $include_files"
else
    echo "[*] All project files";
    include_files=""
    exclude_files="-e Pods/ -e Vendor/ -e WordPressTodayWidget/ -e SFHFKeychainUtils.m -e Constants.m"
fi

#echo "[*] transforming xcodebuild.log into compile_commands.json..."
cd ${temp_dir}
#oclint-xcodebuild -e Pods/ -o ${compile_commands_path}

echo "[*] starting analyzing"

if [ $TRAVIS ]; then
    eval "oclint-json-compilation-database $exclude_files oclint_args \"$oclint_args\" $include_files" > currentLint.log
    cat currentLint.log
    cd ${TRAVIS_BUILD_DIR}
    git checkout $base_commit
    cd ${temp_dir}
    eval "oclint-json-compilation-database $exclude_files oclint_args \"$oclint_args\" $include_files" > baseLint.log
    currentSummary=`cat currentLint.log | grep "Summary: "`
    baseSummary=`cat baseLint.log | grep "Summary: "`
    regex='P1=([[:digit:]]*) P2=([[:digit:]]*) P3=([[:digit:]]*)' 
    if [[ $currentSummary =~ $regex ]]; then
       currentTotalSummary=( ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]})   
    fi
    if [[ $baseSummary =~ $regex ]]; then
       baseTotalSummary=( ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]})
    fi
    errors=0;
    i=0
    n=3
    while [[ $i -lt $n ]]
    do
      if [[ currentTotalSummary[$i] -gt baseTotalSummary[$i] ]]; then
        amount=$((${currentTotalSummary[$i]} - ${baseTotalSummary[$i]}))
        errors+=$amount
        echo "Your changes introduced "$amount "P"$(($i+1))" issue(s)"        
      else
        amount=$((${baseTotalSummary[$i]} - ${currentTotalSummary[$i]}))
        echo "Your changes removed "$amount "P"$(($i+1))" issue(s)"
      fi
      let i++
    done
    # sending message to github
    travis_url="https://travis-ci.org/${TRAVIS_REPO_SLUG}/builds/${TRAVIS_BUILD_ID}/"
    echo $travis_url
    sha=`$TRAVIS_COMMIT_RANGE | cut -d '.' -f 4`
    full_sha=`git rev-parse $sha`
    echo $full_sha
    if [[ $errors -eq 0 ]]; then
      state="success"
      message="OCLinted OK!"
    else
      state="failure"
      message="OCLint detected new issues!"
    fi
    curl -i -H "Content-Type: application/json" \
      -H "Authorization: token ${TRAVIS_OCLINT_GITHUB_TOKEN}" \
      -d "{\"state\": \"${state}\",\"target_url\": \"${travis_url}\",\"description\": \"${message}\",\"context\": \"continuous-integration/oclint\"}" \
      https://api.github.com/repos/${TRAVIS_REPO_SLUG}/statuses/$full_sha

    exit 0      
else 
    eval "oclint-json-compilation-database $exclude_files oclint_args \"$oclint_args\" $include_files $pipe_command"
    exit $?
fi
