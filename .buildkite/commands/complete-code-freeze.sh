#!/bin/bash -eu

RELEASE_NUMBER=$1

if [[ -z "${RELEASE_NUMBER}" ]]; then
    echo "Usage $0 <release number>"
    exit 1
fi

echo '--- :git: Configure Git for release management'
.buildkite/commands/configure-git-for-release-management.sh

echo '--- :git: Checkout release branch'
# FIXME: Don't forget to revert to "release/" only
.buildkite/commands/checkout-release-branch.sh "test-release/$RELEASE_NUMBER"

echo '--- :ruby: Setup Ruby tools'
install_gems

echo '--- :closed_lock_with_key: Access secrets'
bundle exec fastlane run configure_apply

echo '--- :shipit: Complete code freeze'
bundle exec fastlane complete_code_freeze skip_confirm:true
