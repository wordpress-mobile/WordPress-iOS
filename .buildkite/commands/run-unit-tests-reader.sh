#!/bin/bash -eu

# Run this at the start to fail early if value not available
# TODO: We'll need to create a token for Reader
# echo '--- :test-analytics: Configuring Test Analytics'
# export BUILDKITE_ANALYTICS_TOKEN=$BUILDKITE_ANALYTICS_TOKEN_UNIT_TESTS

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

# For the moment, run code signing here just to show it works
# TODO: This will move to the prototype and production builds steps eventually...
bundle exec fastlane update_certs_and_profiles_app_store_reader
