#!/bin/bash -eu

RELEASE_NUMBER=$1

if [[ -z "${RELEASE_NUMBER}" ]]; then
    echo "Usage $0 <release number>"
    exit 1
fi

echo '--- :robot_face: Use bot for Git operations'
source use-bot-for-git

checkout_release_branch "$RELEASE_NUMBER"

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

echo '--- :shipit: Complete code freeze'
bundle exec fastlane complete_code_freeze skip_confirm:true
