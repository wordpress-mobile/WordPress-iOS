#!/bin/bash -eu

# Usage: should-skip-job.sh [--validation|--build|--localization]
# --validation: Skip when changes are limited to documentation, tooling, non-code files, and localization files
# --build: Skip when changes are limited to documentation, tooling, and non-code files
# --localization: Check if any localization files have changed

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

if [ "$1" = "--validation" ]; then
  # Check if changes are limited to documentation, tooling, non-code files, and localization files
  PATTERNS=("${COMMON_PATTERNS[@]}" "${LOCALIZATION_PATTERNS[@]}")
  pr_changed_files --all-match "${PATTERNS[@]}"
elif [ "$1" = "--localization" ]; then
  # Check if any localization files have changed
  # Return true (skip) if NO localization files have changed
  ! pr_changed_files --any-match "${LOCALIZATION_PATTERNS[@]}"
elif [ "$1" = "--build" ]; then
  # Check if changes are limited to documentation, tooling, and non-code files (NOT localization files)
  PATTERNS=("${COMMON_PATTERNS[@]}")
  pr_changed_files --all-match "${PATTERNS[@]}"
else
  echo "Error: Must specify either --validation, --build, or --localization"
  exit 1
fi
