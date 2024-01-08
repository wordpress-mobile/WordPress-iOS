#!/bin/bash -eu

# The Git command line client is not configured in Buildkite.
# At the moment, steps that need Git access can configure it on deman using this script.
# Later on, we should be able to configure it on the agent instead.

curl -L https://api.github.com/meta | jq -r '.ssh_keys | .[]' | sed -e 's/^/github.com /' >> ~/.ssh/known_hosts
git config --global user.email "mobile+wpmobilebot@automattic.com"
git config --global user.name "Automattic Release Bot"

# Buildkite is currently using the HTTPS URL to checkout.
# We need to override it to be able to use the deploy key.
git remote set-url origin git@github.com:wordpress-mobile/WordPress-iOS.git
