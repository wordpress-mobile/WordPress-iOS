#!/bin/bash -eu

echo "--- :rubygems: Setting up Gems"
bundle install

echo "--- :rubocop: Run Rubocop via Danger"
bundle exec danger --fail-on-errors=true
