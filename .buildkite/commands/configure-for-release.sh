#!/bin/bash

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This script must be 'source'd (instead of being called directly as an executable) to work properly"
  exit 1
fi

# Note: Set the flags separately (instead of via the shebang), because that script will be `source`'d and not run directly
set -e
set -u

# The Git command line client is not configured in Buildkite.
# At the moment, steps that need Git access can configure it on deman using this script.
# Later on, we should be able to configure it on the agent instead.
add_host_to_ssh_known_hosts github.com
git config --global user.email "mobile+wpmobilebot@automattic.com"
git config --global user.name "Automattic Release Bot"

echo '--- :robot_face: Use bot for Git operations'
source use-bot-for-git
