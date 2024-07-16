#!/bin/bash -eu

echo "--- :git: Change Git SSH key to fetch private dependencies"

PRIVATE_REPO_FETCH_KEY_NAME="private_repos_key"
add_ssh_key_to_agent "$PRIVATE_REPOS_BOT_KEY" "$PRIVATE_REPO_FETCH_KEY_NAME"
PRIVATE_REPO_FETCH_KEY="$HOME/.ssh/$PRIVATE_REPO_FETCH_KEY_NAME"

add_host_to_ssh_known_hosts 'github.com'

export GIT_SSH_COMMAND="ssh -i $PRIVATE_REPO_FETCH_KEY -o IdentitiesOnly=yes"
echo "Git SSH command is now $GIT_SSH_COMMAND"

# Sentry CLI needs to be up-to-date
brew upgrade sentry-cli

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :swift: Setting up Swift Packages"
install_swiftpm_dependencies

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_and_upload_wordpress_prototype_build
