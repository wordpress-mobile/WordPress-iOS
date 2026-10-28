#!/usr/bin/env bash

# Throwaway validation for wordpress-mobile/WordPress-iOS#26261. Do not merge.

set -euo pipefail

CATALOG=WordPress/Classes/Plurals.xcstrings
EN_STRINGS=WordPress/Resources/en.lproj/Localizable.strings
ARTIFACTS=validation-artifacts
mkdir -p "$ARTIFACTS"

# Fails unless the six word-count originals in the given .strings file all use `%1$d` and none `%1$ld`.
assert_word_count_originals() {
  ruby -rjson -e '
    strings = JSON.parse(`plutil -convert json -o - #{ARGV[0]}`)
    word_count = strings.select { |key, _| key.start_with?("editor.textCounter.wordCount|==|plural.") }
    abort "ASSERTION FAILED: expected 6 word-count originals, found #{word_count.size}" unless word_count.size == 6
    bad = word_count.reject { |_, value| value.include?("%1$d ") && !value.include?("%1$ld") }
    abort "ASSERTION FAILED: originals not using %1$d: #{bad}" unless bad.empty?
    puts "OK: #{word_count.size} word-count originals use %1$d"
  ' "$1"
}

echo "--- :rubygems: Setting up Gems"
install_gems

export GIT_AUTHOR_NAME="Throwaway validation" GIT_COMMITTER_NAME="Throwaway validation"
export GIT_AUTHOR_EMAIL="validation@example.com" GIT_COMMITTER_EMAIL="validation@example.com"

echo "--- :arrow_right: Forward: generate_strings_file_for_glotpress (as at code freeze)"
bundle exec fastlane generate_strings_file_for_glotpress skip_commit:true
cp "$EN_STRINGS" "$ARTIFACTS/en-Localizable.strings"
assert_word_count_originals "$EN_STRINGS"

echo "--- :no_entry: Negative case: the same assertion must fail on trunk's catalog"
git fetch --quiet origin trunk
git show origin/trunk:"$CATALOG" > "$ARTIFACTS/trunk-Plurals.xcstrings"
bundle exec ruby -rjson -r ./fastlane/lanes/plural_strings_helper -e '
  catalog = JSON.parse(File.read(ARGV[0]))
  File.write(ARGV[1], PluralStrings.serialize_legacy_strings(PluralStrings.flat_originals(catalog, PluralStrings::CLDR_ORDER)))
' "$ARTIFACTS/trunk-Plurals.xcstrings" "$ARTIFACTS/trunk-originals.strings"
if negative_output=$(assert_word_count_originals "$ARTIFACTS/trunk-originals.strings" 2>&1); then
  echo "Negative case unexpectedly passed: $negative_output"
  exit 1
fi
echo "$negative_output" | grep -q 'ASSERTION FAILED: originals not using %1\$d' || { echo "Negative case failed for the wrong reason: $negative_output"; exit 1; }
echo "OK: trunk's catalog fails the assertion as expected"

echo "--- :arrow_left: Reverse: download_localized_plurals (as at every beta), without the AI tier"
reverse_log="$ARTIFACTS/download_localized_plurals.log"
env -u ANTHROPIC_API_KEY bundle exec fastlane download_localized_plurals 2>&1 | tee "$reverse_log"
cp "$CATALOG" "$ARTIFACTS/folded-Plurals.xcstrings"
grep -q 'ANTHROPIC_API_KEY not set' "$reverse_log" || { echo "ASSERTION FAILED: AI tier was not skipped"; exit 1; }
grep -q 'Folded plural translations from Localizable.strings' "$reverse_log" || { echo "ASSERTION FAILED: fold did not complete"; exit 1; }

ruby -rjson -e '
  plural = JSON.parse(File.read(ARGV[0]))["strings"]["editor.textCounter.wordCount"]["localizations"]["en"]["variations"]["plural"]
  english = plural.transform_values { |v| v["stringUnit"]["value"] }
  abort "ASSERTION FAILED: English changed by the fold: #{english}" unless english == { "one" => "%1$d word", "other" => "%1$d words" }
  puts "OK: English stays %1$d after the fold"
' "$CATALOG"

xcrun xcstringstool compile "$CATALOG" --output-directory "$ARTIFACTS/compiled"
echo "OK: folded catalog compiles"

echo "--- :memo: Human word-count translations rejected by the fold (expected until GlotPress re-translates)"
rejected=$(grep -c 'rejected .* human translation for "editor.textCounter.wordCount"' "$reverse_log" || true)
[[ "$rejected" -gt 0 ]] || { echo "ASSERTION FAILED: the fold processed no human word-count translations"; exit 1; }
echo "OK: the fold processed and rejected $rejected human %1\$ld word-count translations"
