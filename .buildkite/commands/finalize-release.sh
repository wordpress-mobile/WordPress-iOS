#!/bin/bash -eu

RELEASE_NUMBER=$1

if [[ -z "${RELEASE_NUMBER}" ]]; then
    echo "Usage $0 <release number>"
    exit 1
fi

echo '--- :robot_face: Use bot for Git operations'
source use-bot-for-git

echo '--- :git: Checkout release branch'
.buildkite/commands/checkout-release-branch.sh "$RELEASE_NUMBER"

echo '--- :ruby: Setup Ruby tools'
install_gems

echo '--- :closed_lock_with_key: Access secrets'
bundle exec fastlane run configure_apply

echo '--- :shipit: Finalize release'
bundle exec fastlane finalize_release skip_confirm:true
