#!/bin/bash -eu

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This script must be sourced, not executed, because it exports GIT_SSH_COMMAND."
  exit 1
fi

echo "--- :git: Change Git SSH key to fetch private dependencies"

PRIVATE_REPO_FETCH_KEY_NAME="private_repos_key"
# $PRIVATE_REPOS_BOT_KEY is declared in the `env` file of this pipeline in `mobile-secrets`
add_ssh_key_to_agent "$PRIVATE_REPOS_BOT_KEY" "$PRIVATE_REPO_FETCH_KEY_NAME"
PRIVATE_REPO_FETCH_KEY="$HOME/.ssh/$PRIVATE_REPO_FETCH_KEY_NAME"

export GIT_SSH_COMMAND="ssh -i $PRIVATE_REPO_FETCH_KEY -o IdentitiesOnly=yes"
echo "Git SSH command is now $GIT_SSH_COMMAND"
