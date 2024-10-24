#!/bin/bash -eu

RELEASE_NUMBER=$1

if [[ -z "${RELEASE_NUMBER}" ]]; then
    echo "Usage $0 <release number>"
    exit 1
fi

echo '--- :git: Configure Git for release management'
source .buildkite/commands/configure-for-release.sh

echo '--- :git: Checkout release branch'
.buildkite/commands/checkout-release-branch.sh "$RELEASE_NUMBER"

echo '--- :ruby: Setup Ruby tools'
install_gems

echo '--- :cocoapods: Install Pods (required to check for outdated next)'
install_cocoapods

# Expand this group to surface the information.
#
# It's simpler than capturing the CocoaPods output, filtering, and annotating the build with it.
echo '+++ :cocoapods: Outdated Pods'
bundle exec pod outdated
