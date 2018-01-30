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
    echo "Usage: $exeName command new-version [new-internal-version]"
    echo ""
    echo "   Available commands:"
    echo "      $CMD_CREATE (or $CMD_CREATE_SHORT): creates the new branch and updates the version IDs"
    echo "      $CMD_UPDATE (or $CMD_UPDATE_SHORT): updates the version IDs"
    echo ""
    echo "Example: $exeName create 9.3.0"
    echo "Example: $exeName update 9.3.0.1"
    echo "Example: $exeName update 9.3.0.1 9.3.0.20180129"
    echo ""
    exit 1
}

function showErrorMessage() {
    echo $1 | tee -a $logFile
}

function showMessage() {
    echo $1 | tee -a $logFile
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

    # Create version numbers
    newVer=${nvp[0]}.${nvp[1]}.${nvp[2]}.${nvp[3]}
    newMainVer=${nvp[0]}.${nvp[1]}
    releaseBranch="$releaseBranch$newMainVer"

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

# Shows the configuration the script received
function showConfig() {
    echo "Build version: $newVer"
    echo "Internal version: $newIntVer"
    echo "Release branch: $releaseBranch"
}

# Appends an init line to the log
function startLog() {
    dateTime=`date "+%d-%m-%Y - %H:%M:%S"`
    echo "$exeName started at $dateTime" >> $logFile
}

# Appends a closing line to the log
function stopLog() {
    dateTime=`date "+%d-%m-%Y - %H:%M:%S"`
    echo "$exeName terminated at $dateTime" >> $logFile
    echo "" >> $logFile
    echo "Log location: $logFile"
}

# Writes an error message and exits
function stopOnError() {
    showErrorMessage "Operation failed. Aborting."
    showErrorMessage "See log for further details."
    stopLog
    exit 1
}

# Checks out develop, updates it to origin and creates the release branch
function doBranching() {
    git checkout develop >> $logFile 2>&1 || stopOnError
    git pull origin develop >> $logFile 2>&1 || stopOnError
    git show-ref --verify --quiet "refs/heads/$releaseBranch" >> $logFile 2>&1 
    if [ $? -eq 0 ]; then
        showMessage "Branch $releaseBranch already exists. Skipping creation."
        git checkout $releaseBranch >> $logFile 2>&1 || stopOnError
    else
        git checkout -b $releaseBranch >> $logFile 2>&1 || stopOnError
    fi 
}

# Pushes the new branch to origin
function pushToOrigin() {
    git push origin $releaseBranch >> $logFile 2>&1 || stopOnError
}

# Creates a new branch for the release and updates the relevant files
function createBranch() {
    startLog
    showMessage "Creating new Release branch for version $newMainVer"
    showConfig
    doBranching
    showMessage "Done!"
    showMessage "Updating remote for $newMainVer"
    pushToOrigin
    showMessage "Done!"
    stopLog
}

### Script main
exeName=$(basename "$0" ".sh")

# Params check
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ] || [ -z $1 ]; then
    showUsage
fi

# Load params
cmd=$1
newVer=$2
newIntVer=$3
newMainVer=0
releaseBranch="release/"
logFile="/tmp/manage-version.log"

verifyParams
if [ $cmd == $CMD_CREATE ]; then
    createBranch
elif [ $cmd == $CMD_UPDATE ]; then
    updateBranch
else
    showUsage
fi
