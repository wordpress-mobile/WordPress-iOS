#!/bin/bash -eu

# Usage: should-skip-job.sh --job-type [validation|localization|build]
# --job-type validation: For jobs like unit/instrumented tests, manifest validation…
#     Skip when changes are limited to documentation, tooling, non-code files, and localization files
# --job-type localization: For jobs doing linting, especially ones that might include linting of localization files
#     Check if any localization files have changed
# --job-type build: For jobs building an apk binary, e.g. Assemble, Prototype Builds…
#     Skip when changes are limited to documentation, tooling, and non-code files
#
# Return codes:
# 0 - Job should be skipped (script also handles displaying the message and annotation)
# 1 - Job should not be skipped
# 15 - Error in script parameters

COMMON_PATTERNS=(
  "*.md"
  "*.po"
  "*.pot"
  "*.txt"
  ".gitignore"
  "config/Version.public.xcconfig"
  "docs/**"
  "fastlane/**"
  "Gemfile"
  "Gemfile.lock"
)

LOCALIZATION_PATTERNS=(
  "**/*.strings"
  "**/*.stringsdict"
)

# Define constants for job types
VALIDATION="validation"
BUILD="build"
LOCALIZATION="localization"

# Check if arguments are valid
if [ -z "${1:-}" ] || [ "$1" != "--job-type" ] || [ -z "${2:-}" ]; then
  echo "Error: Must specify --job-type [$VALIDATION|$BUILD|$LOCALIZATION]"
  buildkite-agent step cancel
  exit 15
fi

# Function to display skip message and create annotation
show_skip_message() {
  local job_type=$1
  local message="Skipped ${BUILDKITE_LABEL:-Job} - no relevant files changed"
  local context="skip-$(echo "${BUILDKITE_LABEL:-$job_type}" | sed -E -e 's/[^[:alnum:]]+/-/g' | tr A-Z a-z)"
  
  echo "$message" | buildkite-agent annotate --style "info" --context "$context"
  echo "$message"
}

job_type="$2"
case "$job_type" in
  $VALIDATION)
    # We should skip if changes are limited to documentation, tooling, non-code files, and localization files
    PATTERNS=("${COMMON_PATTERNS[@]}" "${LOCALIZATION_PATTERNS[@]}")
    if pr_changed_files --all-match "${PATTERNS[@]}"; then
      show_skip_message "$job_type"
      exit 0
    fi
    exit 1
    ;;
  $LOCALIZATION)
    # Check if any localization files have changed
    # Return true (skip) if NO localization files have changed
    if ! pr_changed_files --any-match "${LOCALIZATION_PATTERNS[@]}"; then
      show_skip_message "$job_type"
      exit 0
    fi
    exit 1
    ;;
  $BUILD)
    # We should skip if changes are limited to documentation, tooling, and non-code files
    # We'll let the job run (won't skip) if PR includes changes in localization files though
    PATTERNS=("${COMMON_PATTERNS[@]}")
    if pr_changed_files --all-match "${PATTERNS[@]}"; then
      show_skip_message "$job_type"
      exit 0
    fi
    exit 1
    ;;
  *)
    echo "Error: Job type must be either '$VALIDATION', '$BUILD', or '$LOCALIZATION'"
    buildkite-agent step cancel
    exit 15
    ;;
esac
