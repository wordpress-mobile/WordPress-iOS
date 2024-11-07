#!/bin/bash -eu

RELEASE_NUMBER=$1

if [[ -z "${RELEASE_NUMBER}" ]]; then
    echo "Usage $0 <release number>"
    exit 1
fi

echo '--- :robot_face: Use bot for Git operations'
source use-bot-for-git

.buildkite/commands/checkout-release-branch.sh "$RELEASE_NUMBER"

echo '--- :ruby: Setup Ruby tools'
install_gems

echo "--- :swift: Set up Swift Packages"
install_swiftpm_dependencies

echo '--- :closed_lock_with_key: Access secrets'
bundle exec fastlane run configure_apply

echo '--- :shipit: Complete code freeze'
bundle exec fastlane complete_code_freeze skip_confirm:true
