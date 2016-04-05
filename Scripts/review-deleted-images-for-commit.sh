#!/bin/sh
# Using commit hash argument, search for references to deleted image assets.
# Argument 1 is the hash of the commit with asset deletions.
# Argument 2 is the directory to search for usage of the deleted assets.

SEARCH_DIR=$2

# Search the SEARCH_DIR for any matches of the assetname.
searchForUsageOfAsset() {
    assetname=$1
    if (grep -q -r $assetname $SEARCH_DIR)
    then
        echo "Warning: potential usage of deleted asset named \"$assetname\""
    fi
}

# The commit with the deletions.
COMMIT_HASH=$1

# List the deleted files for the commit.
git show --pretty=format: --name-only --diff-filter=D $COMMIT_HASH |

# Iterate the deleted files list input for any .png or .pdf file types.
grep -i ".*\(png\|pdf\)\$" | while read -r line ; do
    filename=$(basename $line)
    # Strip the filename for the asset name.
    assetname=${filename%.*}
    # Ignore images ending the @2x, @3x, etc.
    if [[ "$assetname" == *@*x ]]
    then
        continue
    else
        # Search the directory for usage of the asset.
        searchForUsageOfAsset $assetname
    fi
done

exit 0
