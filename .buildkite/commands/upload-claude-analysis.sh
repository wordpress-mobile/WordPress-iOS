#!/usr/bin/env bash

set -eu

# Uploads the Claude analysis pipeline only when real build/test failures exist.
# Skips when only non-essential jobs failed (e.g. Danger) or nothing failed.

source .buildkite/shared-pipeline-vars

# Query the Buildkite API to get the total count of failed jobs in this build.
build_info=$(curl -sf \
  -H "Authorization: Bearer ${BUILDKITE_TOKEN_FOR_CLAUDE:-}" \
  "https://api.buildkite.com/v2/organizations/${BUILDKITE_ORGANIZATION_SLUG}/pipelines/${BUILDKITE_PIPELINE_SLUG}/builds/${BUILDKITE_BUILD_NUMBER}" \
  2>/dev/null || echo "")

if [ -z "${build_info}" ]; then
  echo "Could not fetch build info; assuming real failures exist, running Claude analysis"
  buildkite-agent pipeline upload .buildkite/claude-analysis.yml
  exit 0
fi

total_failures=$(echo "${build_info}" | jq '[.jobs[] | select(.state == "failed" or .state == "timed_out")] | length' 2>/dev/null || echo "-1")

# Nothing failed — skip Claude analysis.
if [ "${total_failures}" -eq 0 ]; then
  echo "All steps passed, skipping Claude analysis"
  exit 0
fi

# Non-essential steps whose failure alone should NOT trigger Claude analysis.
# Add step keys here as needed.
NON_ESSENTIAL_STEPS=("danger")

# Count how many non-essential steps have a "hard_failed" outcome.
non_essential_failures=0
for step_key in "${NON_ESSENTIAL_STEPS[@]}"; do
  outcome=$(buildkite-agent step get outcome --step "${step_key}" 2>/dev/null || echo "not_run")
  if [ "${outcome}" = "hard_failed" ]; then
    echo "Non-essential job '${step_key}' failed"
    non_essential_failures=$((non_essential_failures + 1))
  fi
done

if [ "${total_failures}" -eq "${non_essential_failures}" ]; then
  echo "Only non-essential job(s) failed (${non_essential_failures}/${total_failures}), skipping Claude analysis"
  exit 0
fi

echo "Real failures detected, running Claude analysis"
buildkite-agent pipeline upload .buildkite/claude-analysis.yml
