#!/bin/bash -eu

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type build; then
  exit 0
fi

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"
"$(dirname "${BASH_SOURCE[0]}")/shared-set-up-distribution.sh"

"$(dirname "${BASH_SOURCE[0]}")/install-secrets.sh"

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_and_upload_jetpack_prototype_build
