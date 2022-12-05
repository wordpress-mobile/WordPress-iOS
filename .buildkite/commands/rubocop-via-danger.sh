#!/bin/bash -eu

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :rubocop: Run Rubocop via Danger"
bundle exec danger --fail-on-errors=true
