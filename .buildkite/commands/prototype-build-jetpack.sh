#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type build; then
  message="Skipping Jetpack Prototype Build - no relevant files changed"
  echo "$message" | buildkite-agent annotate --style "info" --context "skip-prototype-build-jetpack"
  echo "$message"
  exit 0
fi

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"
"$(dirname "${BASH_SOURCE[0]}")/shared-set-up-distribution.sh"

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_and_upload_jetpack_prototype_build
