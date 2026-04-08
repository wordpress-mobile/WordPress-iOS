#!/bin/bash -eu

# Uploads the Claude analysis pipeline only when real build/test failures exist.
# Skips when only non-essential jobs failed (e.g. Danger).

source .buildkite/shared-pipeline-vars

# Non-essential steps whose failure alone should NOT trigger Claude analysis.
# Add step keys here as needed.
NON_ESSENTIAL_STEPS="danger"

for step_key in ${NON_ESSENTIAL_STEPS}; do
  OUTCOME=$(buildkite-agent step get outcome --step "${step_key}" 2>/dev/null || echo "not_run")
  if [ "${OUTCOME}" = "failed" ]; then
    echo "Only non-essential job '${step_key}' failed, skipping Claude analysis"
    exit 0
  fi
done

echo "Real failures detected, running Claude analysis"
buildkite-agent pipeline upload .buildkite/claude-analysis.yml
