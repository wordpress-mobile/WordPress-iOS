#!/bin/sh

### Misc definitions
CMD_CREATE="create-branch"
CMD_CREATE_SHORT="create"
CMD_UPDATE="update-branch"
CMD_UPDATE_SHORT="update"
CMD_FORCE="force-branch"
CMD_FORCE_SHORT="force"

# Regex for "is a number"
IS_A_NUM_RE="^[0-9]+$"

# Color/formatting support
OUTPUT_NORM="\033[0m"
OUTPUT_RED="\033[31m"
OUTPUT_GREEN="\033[32m"
OUTPUT_BOLD="\033[1m"

# PList files
buildPLists=("Info.plist" 
    "WordPressDraftActionExtension/Info.plist"
    "WordPressShareExtension/Info.plist"
    "WordPressTodayWidget/Info.plist")

intPLists=("WordPress-Internal-Info.plist" \
    "WordPressDraftActionExtension/Info-Alpha.plist" \
    "WordPressDraftActionExtension/Info-Internal.plist" \
    "WordPressShareExtension/Info-Alpha.plist" \
    "WordPressShareExtension/Info-Internal.plist" \
    "WordPressTodayWidget/Info-Alpha.plist" \
    "WordPressTodayWidget/Info-Internal.plist" \
    "Wordpress-Alpha-Info.plist")


### Function definitions
# Show script usage, commands and options
function showUsage() {
    # Help message
    echo "Usage: $exeName command new-version [new-internal-version]"
    echo ""
    echo "   Available commands:"
    echo "      $CMD_CREATE (or $CMD_CREATE_SHORT): creates the new branch and updates the version IDs"
    echo "      $CMD_UPDATE (or $CMD_UPDATE_SHORT): updates the version IDs"
    echo "      $CMD_FORCE (or $CMD_FORCE_SHORT): force the update to the provided version, skipping the checks."
    echo ""
    echo "Example: $exeName create 9.3.0"
    echo "Example: $exeName update 9.3.0.1"
    echo "Example: $exeName update 9.3.0.1 9.3.0.20180129"
    echo ""
    exit 1
}

function showErrorMessage() {
    message=$1
    echo "$OUTPUT_RED$message$OUTPUT_NORM"
    echo $message >> $logFile
}

function showOkMessage() {
    message=$1
    echo "$OUTPUT_GREEN$message$OUTPUT_NORM" 
    echo $message >> $logFile
}

function showTitleMessage() {
    message=$1
    echo "$OUTPUT_BOLD$message$OUTPUT_NORM" 
    echo $message >> $logFile
}

function showMessage() {
    echo "$1" | tee -a $logFile
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

    if [ $cmd == $CMD_FORCE ] || [ $cmd == $CMD_FORCE_SHORT ]; then
        cmd=$CMD_FORCE
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
    showMessage "Current build version: $currentVer"
    showMessage "Current internal version: $currentIntVer"
    showMessage "New build version: $newVer"
    showMessage "New internal version: $newIntVer"
    showMessage "Release branch: $releaseBranch"
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

# Updates the keys in download_metadata.swift and AppStoreStrings.po
function updateGlotPressKey() {
    dmFile="./fastlane/download_metadata.swift"
    if [ -f $dmFile ]; then
        sed -i '' "s/let glotPressWhatsNewKey.*/let glotPressWhatsNewKey = \"v$newMainVer-whats-new\"/" $dmFile
    else
        showErrorMessage "Can't find $dmFile."
        stopOnError
    fi

    assFile="../WordPress/Resources/AppStoreStrings.po"
    if [ -f $assFile ]; then
        sed -i '' "s#.*whats-new\"#msgctxt \"v$newMainVer-whats-new\"#"  $assFile >> $logFile 2>&1 || stopOnError
    else
        showErrorMessage "Can't find $assFile."
        stopOnError
    fi
}

# Updates the app version in Fastlane Deliver file
function updateFastlaneDeliver() {
    fdFile="./fastlane/Deliverfile"
    if [ -f $fdFile ]; then
        sed -i '' "s/app_version.*/app_version \"$newMainVer\"/" $fdFile
    else
        showErrorMessage "Can't find $fdFile."
        stopOnError
    fi
}

# Updates a list of plist files with the provided version 
function updatePlistArray() {
    declare -a fileList=("${!1}")
    updateVer=$2

    for i in "${fileList[@]}"
    do
        cFile="../WordPress/$i"
        if [ -f "$cFile" ]; then
            echo "Updating $cFile to version $2" >> $logFile 2>&1
            sed -i '' "$(awk '/CFBundleShortVersionString/{ print NR + 1; exit }' "$cFile")s/<string>.*/<string>$newMainVer<\/string>/" "$cFile" >> $logFile 2>&1 || stopOnError
            sed -i '' "$(awk '/CFBundleVersion/{ print NR + 1; exit }' "$cFile")s/<string>.*/<string>$updateVer<\/string>/" "$cFile" >> $logFile 2>&1 || stopOnError
        else
            stopOnError "$cFile  not found"
        fi
    done
}

# Updates the pList files
function updatePLists() {
    updatePlistArray buildPLists[@] "$newVer"
    updatePlistArray intPLists[@] "$newIntVer"
}

# Updates pLists files and fastlane deliver on the current branch
function updateBranch() {
    if [ $cmd == $CMD_UPDATE ]; then
        startLog
        checkVersions
        showTitleMessage "Updating the current branch to version $newMainVer..."
        showConfig
    fi

    showMessage "Updating pLists..."
    updatePLists
    showMessage "Done!"

    if [ $cmd == $CMD_UPDATE ]; then
        showOkMessage "Success!"
        stopLog
    fi
}

# Creates a new branch for the release and updates the relevant files
function createBranch() {
    startLog
    if [ $cmd != $CMD_FORCE ]; then
        checkVersions
        showTitleMessage "Creating new Release branch for version $newMainVer..."
    else
        showTitleMessage "Forcing branch for version $newMainVer..."
    fi
    showConfig
    doBranching
    showMessage "Done!"
    showMessage "Updating glotPressKeys..."
    updateGlotPressKey
    showMessage "Done!"
    showMessage "Updating Fastlane deliver file..."
    updateFastlaneDeliver
    showMessage "Done!"
    updateBranch
    showOkMessage "Success!"
    stopLog
}

# Reads a version from a Plist file
function readVersion() {
    cFile="../WordPress/$1"
    if [ -f "$cFile" ]; then
        tmp=$(sed -n "$(awk '/CFBundleVersion/{ print NR + 1; exit }' "$cFile")p" "$cFile" | cut -d'>' -f 2 | cut -d'<' -f 1)
    else
        showErrorMessage "$cFile not found. Can't read version. Are you in the correct branch/folder?"
        exit 1
    fi
}

# Reads the current internal and external versions
function getCurrentVersions() {
    printf "Reading current version in this branch..."
    readVersion ${buildPLists[0]}
    currentVer=$tmp

    readVersion ${intPLists[0]}
    currentIntVer=$tmp 
    echo "Done."
}

# Check coherency between current and updating version
function checkVersion() {
    firstVer=$1
    secondVer=$2
    if [ $firstVer == $secondVer ]; then
        showErrorMessage "Current branch is already on version $firstVer"
        stopOnError
    fi

    nvp=( ${firstVer//./ } )
    cvp=( ${secondVer//./ } )

    idx=0
    for i in "${nvp[@]}"
    do
        if [ $i -gt ${cvp[idx]} ]; then
            return
        elif [ $i -lt ${cvp[idx]} ]; then
            showErrorMessage "New version $firstVer is lower than current version $secondVer"
            stopOnError
        fi
        ((idx++))
    done
}

# Check coherency between current and updating versions
function checkVersions() {
    checkVersion $newVer $currentVer
    checkVersion $newIntVer $currentIntVer
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
currentVer=0
currentIntVer=0
releaseBranch="release/"
logFile="/tmp/manage-version.log"

verifyParams
getCurrentVersions
if [ $cmd == $CMD_CREATE ] || [ $cmd == $CMD_FORCE ]; then
    createBranch
elif [ $cmd == $CMD_UPDATE ]; then
    updateBranch
else
    showUsage
fi
