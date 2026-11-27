#!/bin/bash -eu

# Usage: should-skip-job.sh [validation|localization|build|swift-packages]
# Prints a skip reason, or false to run. Both exit 0; invalid arguments exit 15.
# Whole jobs use this output at pipeline upload; swift-packages selects part of a job.
# Only webhook PRs can skip. WORDPRESS_CI_FULL_BUILD=1 forces a full run.

run_job() { echo false; exit 0; }

job="${1:-}"
case "$job" in
  validation|localization|build|swift-packages) ;;
  *) echo "Unknown job type: $job" >&2; exit 15 ;;
esac

if [[ "${WORDPRESS_CI_FULL_BUILD:-}" == 1 || "${BUILDKITE_SOURCE:-}" != webhook ||
      -n "${BUILDKITE_TAG:-}" || ! "${BUILDKITE_PULL_REQUEST:-}" =~ ^[0-9]+$ ]]; then
  run_job
fi

# Documentation and release metadata are unrelated to all four jobs.
PATTERNS=(
  '*.md' '*.po' '*.pot' 'docs/*' '.gitignore' 'config/Version.public.xcconfig'
  'RELEASE-NOTES.txt'
  'WordPress/Resources/beta_app_description.txt' 'WordPress/Resources/release_notes.txt'
  'WordPress/Jetpack/Resources/beta_app_description.txt' 'WordPress/Jetpack/Resources/release_notes.txt'
)
if [[ "$job" == localization ]]; then
  # The GlotPress lane extracts strings from source, merges English resources, and
  # depends on Fastlane and its gems. Only its App Store metadata can be ignored.
  PATTERNS+=('fastlane/appstoreres/*' 'fastlane/metadata/*' 'fastlane/jetpack_metadata/*' 'fastlane/reader_metadata/*')
else
  PATTERNS+=('fastlane/*' 'Gemfile' 'Gemfile.lock')
fi
LOCALIZATION_PATTERNS=('*.strings' '*.stringsdict')
case "$job" in
  validation) PATTERNS+=("${LOCALIZATION_PATTERNS[@]}") ;;
  swift-packages)
    # App-only changes still need string-catalog coverage in the same job.
    PATTERNS+=("${LOCALIZATION_PATTERNS[@]}" 'WordPress/*' 'Tests/*' 'Sources/*')
    ;;
esac

pr_changed_files --all-match "${PATTERNS[@]}" || run_job

echo "No relevant files changed"
