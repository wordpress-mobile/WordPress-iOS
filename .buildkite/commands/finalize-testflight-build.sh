#!/usr/bin/env bash

set -euo pipefail

APP="${1:?Usage: finalize-testflight-build.sh <wordpress|jetpack>}"

MARKETING_VERSION="$(buildkite-agent meta-data get "testflight_marketing_version_${APP}")"
BUILD_CODE="$(buildkite-agent meta-data get "testflight_build_code_${APP}")"

echo "--- :rubygems: Installing gems"
bundle install

echo "--- :testflight: Waiting for ${APP} ${BUILD_CODE} to finish processing"
bundle exec fastlane finalize_internal_testflight_build \
  app:"${APP}" \
  marketing_version:"${MARKETING_VERSION}" \
  build_code:"${BUILD_CODE}"
