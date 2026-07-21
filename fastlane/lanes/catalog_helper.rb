# frozen_string_literal: true

require 'json'

# Helpers for the build-free catalog generation pipeline (genstrings-coverage verification + needs_review
# reconciliation). Plain Ruby with no fastlane dependencies, so it's unit-testable directly — the lanes in
# `localization_catalog.rb` call into it.
module CatalogHelper
  module_function

  # --- coverage verification: catalog vs the legacy genstrings output -------------------------------------

  # printf-style format specifier (incl. positional %N$ and length modifiers). The space flag (`% d`) is
  # deliberately excluded: it's vanishingly rare in our strings, and allowing it makes `% <letter>` match
  # inside ordinary prose ("100% sure" → "% s"), corrupting the canonical form used for the coverage compare.
  FORMAT_SPECIFIER = /%(?:\d+\$)?[#0\-+']*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|h|ll|l|L|q|z|t|j)?[@dDiuUxXoOfFeEgGaAcCsSpn%]/

  # Keys present in `reference` (e.g. genstrings output) but absent from `catalog_keys`, compared on the
  # format-canonical form (so `%li` vs `%1$li` don't read as false gaps). Both lists arrive already decoded —
  # genstrings keys via `L10nHelper.read_strings_file_as_hash` (Apple's `plutil`), catalog keys straight from
  # the parsed JSON — so there's no unescaping to do here.
  def coverage_gap(reference, catalog_keys)
    catalog_canonical = catalog_keys.to_set { |key| canonical(key) }
    reference.reject { |key| catalog_canonical.include?(canonical(key)) }
  end

  # Strip the positional index from each format specifier so a source-form specifier (%li) and its normalized form
  # (%1$li) compare equal, while specifiers of a DIFFERENT argument type stay distinct. The positional `N$` prefix
  # is the only thing that differs between the two extraction paths (genstrings vs xcstringstool) for the same
  # source literal; collapsing every specifier to one token — as this did before — conflated `%d days` with
  # `%@ days` and masked a genuinely-dropped key behind a same-prose sibling of a different type.
  def canonical(key)
    key.gsub(FORMAT_SPECIFIER) { |specifier| specifier.sub(/\A%\d+\$/, '%') }
  end

  # --- immutable-key enforcement -------------------------------------------------------------------------

  # `xcstringstool sync` does NOT touch an existing key whose English source VALUE changed in place: it leaves
  # both the stored English and the affected translations as-is (verified — source "Settings" → "Preferences"
  # left en="Settings" and fr="translated"). The in-Xcode build reconciles this; the standalone CLI doesn't.
  #
  # Localization keys are IMMUTABLE, so an in-place reword is a rule violation, not something to reconcile:
  # rewording must mint a NEW key, otherwise the old key silently keeps translations of the OLD English — a
  # stale translation the fold can't distinguish from a current one. This reports the offending keys so the
  # lane can hard-fail (rename the key, or revert the English change).
  #
  # Naturally scoped to explicit-key strings: a key-as-source string has no stored `en` value (its key IS its
  # English), and rewording one changes the KEY — sync handles that as new/stale, not a value change — so it
  # never appears here. Plurals don't either (their English is a plural variation, not a flat `stringUnit`).
  #
  # @param catalog [Hash] parsed `.xcstrings`
  # @param current_en [Hash{String=>String}] key => freshly-extracted English value
  # @return [Array<String>] keys whose stored English no longer matches the source (empty ⇒ nothing reworded)
  def reworded_keys(catalog, current_en)
    (catalog['strings'] || {}).filter_map do |key, entry|
      stored = entry.dig('localizations', 'en', 'stringUnit', 'value')
      fresh = current_en[key]
      key if stored && fresh && stored != fresh
    end
  end
end
