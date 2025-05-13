#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type localization; then
  message="Skipping Localization Lint - no localization files changed"
  echo "$message" | buildkite-agent annotate --style "info" --context "skip-localization-lint"
  echo "$message"
  exit 0
fi

echo "--- :writing_hand: Copy Files"
mkdir -pv ~/.configure/wordpress-ios/secrets
cp -v fastlane/env/project.env-example ~/.configure/wordpress-ios/secrets/project.env

lint_localized_strings_format
