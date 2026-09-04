#!/bin/bash -eu

echo "--- :rubygems: Setting up Gems"
install_gems

# The claim under test is that readonly runs need no Enterprise key, so drop the variables
# whether or not the agent's environment carries them.
unset APP_STORE_CONNECT_API_KEY_KEY_ID_ENTERPRISE
unset APP_STORE_CONNECT_API_KEY_ISSUER_ID_ENTERPRISE
unset APP_STORE_CONNECT_API_KEY_KEY_ENTERPRISE

echo "--- :closed_lock_with_key: Readonly must succeed with no Enterprise key"
bundle exec fastlane update_certs_and_profiles_enterprise

echo "--- :closed_lock_with_key: Non-readonly must fail through the missing-variable guard"
set +e
output=$(bundle exec fastlane update_certs_and_profiles_wordpress_enterprise readonly:false 2>&1)
status=$?
set -e
echo "$output"

if [ $status -eq 0 ]; then
  echo "^^^ +++"
  echo "Expected a failure without APP_STORE_CONNECT_API_KEY_KEY_ID_ENTERPRISE, but the lane succeeded."
  exit 1
fi

if ! grep -q "APP_STORE_CONNECT_API_KEY_KEY_ID_ENTERPRISE' is not set" <<< "$output"; then
  echo "^^^ +++"
  echo "The lane failed, but not through the missing-variable guard, so this run proves nothing."
  exit 1
fi

echo "Guard fired as expected."
