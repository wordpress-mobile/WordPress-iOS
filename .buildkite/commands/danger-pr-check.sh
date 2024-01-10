#!/bin/bash -eu

HOST="github.com"
echo "--- :github: Adding ${HOST} to '~/.ssh/known_hosts'..."
for ip in $(dig @8.8.8.8 "${HOST}" +short); do ssh-keyscan "${HOST}","$ip"; ssh-keyscan "$ip"; done 2>/dev/null >> ~/.ssh/known_hosts || true

echo "--- :rubygems: Setting up Gems"
bundle install

echo "--- Running Danger: PR Check"
bundle exec danger --fail-on-errors=true --remove-previous-comments --danger_id=pr-check
