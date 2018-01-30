#!/bin/sh

### Misc definitions
CMD_CREATE="create-branch"
CMD_CREATE_SHORT="create"
CMD_UPDATE="update-branch"
CMD_UPDATE_SHORT="update"

IS_A_NUM_RE="^[0-9]+$"

### Function definitions
# Show script usage, commands and options
function showUsage() {
    # Help message
    echo "Usage: $exename command new-version [new-internal-version]"
    echo ""
    echo "   Available commands:"
    echo "      $CMD_CREATE (or $CMD_CREATE_SHORT): creates the new branch and updates the version IDs"
    echo "      $CMD_UPDATE (or $CMD_UPDATE_SHORT): updates the version IDs"
    echo ""
    echo "Example: $exename create 9.3.0"
    echo "Example: $exename update 9.3.0.1"
    echo "Example: $exename update 9.3.0.1 9.3.0.20180129"
    echo ""
    exit 1
}

function showErrorMessage() {
    echo $1
}

# Verifies the command against the known ones and normalize to the extended version
# Shows script usage in case of unknown command
function verifyCommand() {
    if [ $cmd == $CMD_CREATE ] || [ $cmd == $CMD_CREATE_SHORT ]; then
        cmd=$CMD_CREATE
        return
    fi

    if [ $cmd == $CMD_UPDATE ] || [ $cmd == $CMD_UPDATE_SHORT ]; then
        cmd=$CMD_UPDATE
        return
    fi

    showUsage
}

# Check version length, format and coherency.
# Also creates the internal version if it doesn't exists
function verifyVersion() {
    nvp=( ${newVer//./ } )

    # Check version array has at least 2 elements
    if [ "${#nvp[@]}" -lt 2 ]; then
        showErrorMessage "Version string must contain Major and Minor numbers at least"
        exit 1
    fi

    # Check version array has no more than 4 elements
    if [ "${#nvp[@]}" -gt 4 ]; then
        showErrorMessage "Version string can contain no more than Major, Minor, Release and Build numbers"
        exit 1
    fi

    # Assign 3rd and 4th el to zero if they doesn't exist
    if [ x${nvp[2]} == x ]; then
        nvp[2]=0
    fi

    if [ x${nvp[3]} == x ]; then
        nvp[3]=0
    fi

    # Check every part is a number
    for i in "${nvp[@]}"
    do
        if ! [[ $i =~ $IS_A_NUM_RE ]] ; then
            showErrorMessage "Version value can only contains numbers" 
            exit 1
        fi
    done

    # Recreate version number
    newVer=${nvp[0]}.${nvp[1]}.${nvp[2]}.${nvp[3]}

    # If internal version exists, check if has the same major, minor, release
    # otherwise, create one
    if [ x$newIntVer == x ]; then
        todayDate=`date +%Y%m%d`
        newIntVer=${newVer%.*}.$todayDate
    elif [ ${newVer%.*} != ${newIntVer%.*} ]; then
        showErrorMessage "Internal and external versions don't match."
        exit 1
    fi
}

# Verifies the command and the version
function verifyParams() {
    verifyCommand
    verifyVersion
}

### Script main
exename=$(basename "$0" ".sh")

# Params check
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    showUsage
fi

# Load params
cmd=$1
newVer=$2
newIntVer=$3


verifyParams

#test
echo $cmd
echo $newVer
echo $newIntVer