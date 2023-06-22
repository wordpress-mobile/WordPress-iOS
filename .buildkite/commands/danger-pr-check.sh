#!/bin/bash -eu

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- Running Danger"
bundle exec danger --fail-on-errors=true --dangerfile=.buildkite/danger/Dangerfile-pr-check --danger_id=pr-check
