#!/bin/bash -eu

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- 📦 Downloading Build Artifacts"
buildkite-agent artifact download build/results/WordPress.xcresult.zip ./ --step unit_tests_wordpress
buildkite-agent artifact download build/results/WordPress.xml ./ --step unit_tests_wordpress
cd build/results && unzip WordPress.xcresult.zip && cd -

echo "--- Running Danger: PR Check"
bundle exec danger --fail-on-errors=true --dangerfile=.buildkite/danger/Dangerfile-post-build --danger_id=post-build
