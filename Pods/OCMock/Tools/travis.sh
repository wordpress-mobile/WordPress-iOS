#!/bin/bash    

# adapted from: https://gist.github.com/henrikhodne/73151fccea7af3201f63

 
SCRIPT_DIR=$(dirname "$0")

run_xcodebuild ()
{
	local scheme=$1
             
	xcodebuild -scheme "$scheme" -configuration Debug test OBJROOT="$PWD/build" SYMROOT="$PWD/build"

	local status=$?
 
	return $status
}
 
build_scheme ()
{
	local scheme=$1
 
	run_xcodebuild "$scheme" 2>&1 | awk -f "$SCRIPT_DIR/xcodebuild.awk"
 
	local awkstatus=$?
	local xcstatus=${PIPESTATUS[0]}
 
	if [ "$xcstatus" -eq "65" ]
	then
		echo "*** Error building scheme $scheme"
	elif [ "$awkstatus" -eq "1" ]
	then
		return $awkstatus
	fi
 
	return $xcstatus
}
 
echo "*** Building..."
 
build_scheme OCMock || exit $?
#build_scheme OCMockLib || exit $?
