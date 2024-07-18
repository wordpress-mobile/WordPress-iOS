#!/bin/bash -eu

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This script must be sourced, not executed, because it exports GIT_SSH_COMMAND."
  exit 1
fi

echo "--- :git: Change Git SSH key to fetch private dependencies"

WORDPRESS_RS_FETCH_KEY_NAME="read_only_deploy_key_to_fetch_wordpress_rs"
# $WORDPRESS_RS_KEY is declared in the `env` file of this pipeline in `mobile-secrets`
add_ssh_key_to_agent "$WORDPRESS_RS_KEY" "$WORDPRESS_RS_FETCH_KEY_NAME"
WORDPRESS_RS_FETCH_KEY="$HOME/.ssh/$WORDPRESS_RS_FETCH_KEY_NAME"

export GIT_SSH_COMMAND="ssh -i $WORDPRESS_RS_FETCH_KEY -o IdentitiesOnly=yes"
echo "Git SSH command is now $GIT_SSH_COMMAND"
