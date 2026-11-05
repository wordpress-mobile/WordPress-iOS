#!/usr/bin/env bash

# Throwaway validation for wordpress-mobile/WordPress-iOS#26263. Do not merge.

set -euo pipefail

CATALOG=WordPress/Classes/Plurals.xcstrings
HELPER=fastlane/lanes/plural_strings_helper.rb
SOURCE_CHANGE_BRANCH=ainfra-3482-use-1d-instead-of-1ld-in-wordpress-ios-plural-word-count
ARTIFACTS=validation-artifacts
mkdir -p "$ARTIFACTS"

# Machine word-count cells in the given catalog that still carry the old `%1$ld`.
count_stale_cells() {
  ruby -rjson -e '
    localizations = JSON.parse(File.read(ARGV[0]))["strings"]["editor.textCounter.wordCount"]["localizations"]
    cells = localizations.reject { |locale, _| locale == "en" }.values.flat_map { |l| l.dig("variations", "plural").to_h.values }
    puts cells.count { |c| c["stringUnit"]["state"] == "needs_review" && c["stringUnit"]["value"].include?("%1$ld") }
  ' "$1"
}

fold() {
  env -u ANTHROPIC_API_KEY bundle exec fastlane download_localized_plurals 2>&1 | tee "$1"
  grep -q 'ANTHROPIC_API_KEY not set' "$1" || { echo "ASSERTION FAILED: AI tier was not skipped"; exit 1; }
  grep -q 'Folded plural translations from Localizable.strings' "$1" || { echo "ASSERTION FAILED: fold did not complete"; exit 1; }
}

echo "--- :rubygems: Setting up Gems"
install_gems

export GIT_AUTHOR_NAME="Throwaway validation" GIT_COMMITTER_NAME="Throwaway validation"
export GIT_AUTHOR_EMAIL="validation@example.com" GIT_COMMITTER_EMAIL="validation@example.com"

echo "--- :inbox_tray: Input: the current catalog with #26261's English change"
git fetch --quiet origin trunk
git fetch --quiet origin "$SOURCE_CHANGE_BRANCH"
source_change=$(git rev-parse FETCH_HEAD)
git show "$source_change:$CATALOG" > "$ARTIFACTS/input-Plurals.xcstrings"
cp "$ARTIFACTS/input-Plurals.xcstrings" "$CATALOG"
stale_before=$(count_stale_cells "$CATALOG")
[[ "$stale_before" -gt 0 ]] || { echo "ASSERTION FAILED: the input has no stale cells, so nothing below can go red"; exit 1; }
echo "OK: input has $stale_before stale %1\$ld machine word-count cells"

echo "--- :no_entry: Negative case: trunk's helper must keep the stale cells"
git show "origin/trunk:$HELPER" > "$HELPER"
fold "$ARTIFACTS/fold-without-fix.log"
cp "$CATALOG" "$ARTIFACTS/folded-without-fix-Plurals.xcstrings"
stale_without_fix=$(count_stale_cells "$CATALOG")
[[ "$stale_without_fix" -eq "$stale_before" ]] || { echo "ASSERTION FAILED: expected $stale_before stale cells without the fix, found $stale_without_fix"; exit 1; }
if grep -q 'dropped stale' "$ARTIFACTS/fold-without-fix.log"; then
  echo "ASSERTION FAILED: trunk's helper reported dropping cells"
  exit 1
fi
echo "OK: without the fix all $stale_without_fix stale cells survive the fold"

echo "--- :white_check_mark: Fix: this PR's helper must drop every stale cell"
git checkout --quiet HEAD -- "$HELPER"
cp "$ARTIFACTS/input-Plurals.xcstrings" "$CATALOG"
fold "$ARTIFACTS/fold-with-fix.log"
cp "$CATALOG" "$ARTIFACTS/folded-with-fix-Plurals.xcstrings"
stale_with_fix=$(count_stale_cells "$CATALOG")
[[ "$stale_with_fix" -eq 0 ]] || { echo "ASSERTION FAILED: $stale_with_fix stale cells survived the fix"; exit 1; }
echo "OK: no stale cells left"

dropped=$(grep -c 'dropped stale .* machine translation for "editor.textCounter.wordCount"' "$ARTIFACTS/fold-with-fix.log" || true)
[[ "$dropped" -eq "$stale_before" ]] || { echo "ASSERTION FAILED: expected $stale_before drop warnings, found $dropped"; exit 1; }
echo "OK: the fold warned about each of the $dropped dropped cells"

dropped_elsewhere=$(grep 'dropped stale' "$ARTIFACTS/fold-with-fix.log" | grep -vc '"editor.textCounter.wordCount"' || true)
[[ "$dropped_elsewhere" -eq 0 ]] || { echo "ASSERTION FAILED: dropped $dropped_elsewhere cells of keys whose English did not change"; exit 1; }
echo "OK: no cell of any other key was dropped"

xcrun xcstringstool compile "$CATALOG" --output-directory "$ARTIFACTS/compiled"
echo "OK: folded catalog compiles"
