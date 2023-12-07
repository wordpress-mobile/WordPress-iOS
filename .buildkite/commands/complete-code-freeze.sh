#!/bin/bash -eu

echo '--- :git: Configure Git for release management'
.buildkite/commands/configure-git-for-release-management.sh
.buildkite/commands/checkout-release-branch.sh

echo '--- :ruby: Setup Ruby tools'
install_gems

echo '--- :closed_lock_with_key: Access secrets'
bundle exec fastlane run configure_apply

echo '--- :shipit: Complete code freeze'
bundle exec fastlane complete_code_freeze skip_confirm:true
