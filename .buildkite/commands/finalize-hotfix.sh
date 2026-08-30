#!/bin/bash -eu

RELEASE_NUMBER=$1

if [[ -z "${RELEASE_NUMBER}" ]]; then
    echo "Usage $0 <release number>"
    exit 1
fi

echo '--- :robot_face: Use bot for Git operations'
source use-bot-for-git

checkout_release_branch "$RELEASE_NUMBER"

echo '--- :ruby: Setup Ruby tools'
install_gems

echo '--- :shipit: Finalize hotfix'
bundle exec fastlane finalize_hotfix_release skip_confirm:true
