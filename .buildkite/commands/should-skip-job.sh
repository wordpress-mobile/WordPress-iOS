#!/bin/bash -eu

# Usage: should-skip-job.sh --job-type [validation|build|localization]
# --job-type validation: Skip when changes are limited to documentation, tooling, non-code files, and localization files
# --job-type build: Skip when changes are limited to documentation, tooling, and non-code files
# --job-type localization: Check if any localization files have changed

COMMON_PATTERNS=(
  "*.md"
  "*.pot"
  "*.txt"
  ".gitignore"
  "config/Version.Public.xcconfig"
  "docs/**"
  "fastlane/**"
  "Gemfile"
  "Gemfile.lock"
)

LOCALIZATION_PATTERNS=(
  "**/*.strings"
  "**/*.stringsdict"
)

# Check if arguments are valid
if [ -z "${1:-}" ] || [ "$1" != "--job-type" ] || [ -z "${2:-}" ]; then
  echo "Error: Must specify --job-type [validation|build|localization]"
  buildkite-agent step cancel
  exit 15
fi

case "$2" in
  "validation")
    # We should skip if changes are limited to documentation, tooling, non-code files, and localization files
    PATTERNS=("${COMMON_PATTERNS[@]}" "${LOCALIZATION_PATTERNS[@]}")
    pr_changed_files --all-match "${PATTERNS[@]}"
    ;;
  "localization")
    # Check if any localization files have changed
    # Return true (skip) if NO localization files have changed
    ! pr_changed_files --any-match "${LOCALIZATION_PATTERNS[@]}"
    ;;
  "build")
    # We should skip if changes are limited to documentation, tooling, and non-code files
    # We'll let the job run (won't skip) if PR includes changes in localization files though
    PATTERNS=("${COMMON_PATTERNS[@]}")
    pr_changed_files --all-match "${PATTERNS[@]}"
    ;;
  *)
    echo "Error: Job type must be either 'validation', 'build', or 'localization'"
    buildkite-agent step cancel
    exit 15
    ;;
esac
