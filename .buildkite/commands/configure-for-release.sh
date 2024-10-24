#!/bin/bash -eu

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This script must be 'source'd (instead of being called directly as an executable) to work properly"
  exit 1
fi

# The Git command line client is not configured in Buildkite.
# At the moment, steps that need Git access can configure it on deman using this script.
# Later on, we should be able to configure it on the agent instead.
add_host_to_ssh_known_hosts github.com
git config --global user.email "mobile+wpmobilebot@automattic.com"
git config --global user.name "Automattic Release Bot"

echo '--- :robot_face: Use bot for git operations'
source use-bot-for-git
