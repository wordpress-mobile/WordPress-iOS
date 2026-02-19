#!/bin/bash -eu

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type validation; then
  exit 0
fi

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

# For the moment, run code signing here just to show it works
# TODO: This will move to the prototype and production builds steps eventually...
bundle exec fastlane update_certs_and_profiles_app_store_reader
