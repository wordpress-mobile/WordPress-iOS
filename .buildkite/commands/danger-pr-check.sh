#!/bin/bash -eu

export DANGER_GITHUB_API_TOKEN=${GITHUB_TOKEN}

echo "--- :rubygems: Setting up Gems"
bundle install

echo "--- Running Danger: PR Check"
bundle exec danger --fail-on-errors=true --dangerfile=.buildkite/danger/Dangerfile --remove-previous-comments --danger_id=pr-check
