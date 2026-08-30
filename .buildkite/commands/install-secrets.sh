#!/usr/bin/env bash

set -euo pipefail

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply
