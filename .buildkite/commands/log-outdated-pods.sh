#!/bin/bash -eu

RELEASE_NUMBER=$1

if [[ -z "${RELEASE_NUMBER}" ]]; then
    echo "Usage $0 <release number>"
    exit 1
fi

echo '--- :git: Checkout release branch'
.buildkite/commands/configure-git-for-release-management.sh
.buildkite/commands/checkout-release-branch.sh "$RELEASE_NUMBER"

echo '--- :ruby: Setup Ruby tools'
install_gems

echo '--- :closed_lock_with_key: Access secrets'
bundle exec fastlane run configure_apply

echo '--- :cocoapods: Install Pods (required to check for outdated next)'
install_cocoapods

echo '+++ :cocoapods: Outdated Pods'
bundle exec pod outdated
