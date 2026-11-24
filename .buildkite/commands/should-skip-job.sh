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

# Preserve the existing documentation, tooling and version exclusions.
PATTERNS=(
  '*.md' '*.po' '*.pot' '*.txt' '.gitignore' 'config/Version.public.xcconfig'
  'docs/**' 'fastlane/**' 'Gemfile' 'Gemfile.lock'
)
LOCALIZATION_PATTERNS=('**/*.strings' '**/*.stringsdict')
case "$job" in
  validation) PATTERNS+=("${LOCALIZATION_PATTERNS[@]}") ;;
  swift-packages)
    # App-only changes still need string-catalog coverage in the same job.
    PATTERNS+=("${LOCALIZATION_PATTERNS[@]}" 'WordPress/*' 'Tests/*' 'Sources/*')
    ;;
esac

# Include both paths of renames on toolkit versions before #243.
config_index=${GIT_CONFIG_COUNT:-0}
export GIT_CONFIG_COUNT=$((config_index + 1))
export "GIT_CONFIG_KEY_${config_index}=diff.renames" "GIT_CONFIG_VALUE_${config_index}=false"

if [[ "$job" == localization ]]; then
  # A failed or empty diff must not look like "no localization changes".
  pr_changed_files || run_job
  relevant=$(pr_changed_files --stdout --any-match "${LOCALIZATION_PATTERNS[@]}") || run_job
  [[ "$relevant" == false ]] || run_job
else
  pr_changed_files --all-match "${PATTERNS[@]}" || run_job
fi

echo "No relevant files changed"
