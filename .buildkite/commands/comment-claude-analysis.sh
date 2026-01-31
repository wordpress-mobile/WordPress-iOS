#!/bin/bash -eu

# The claude-analysis step only runs when there are build failures,
# so if it ran (and soft_failed), it means there were failures that Claude analyzed.
CLAUDE_OUTCOME=$(buildkite-agent step get outcome --step claude-analysis 2>/dev/null || echo "not_run")

if [[ "${CLAUDE_OUTCOME}" == "soft_failed" ]]; then
  comment_on_pr --id claude-build-analysis "## 🤖 Build Failure Analysis

This build has failures. Claude has analyzed them - <a href=\"${BUILDKITE_BUILD_URL}/annotations\" target=\"_blank\">check the build annotations</a> for details."
else
  # Remove the comment if the build is now passing (claude-analysis did not run)
  comment_on_pr --id claude-build-analysis --if-exist delete
fi

