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

  # Collapse format specifiers to a single token so source-form (%li) and normalized (%1$li) compare equal.
  def canonical(key)
    key.gsub(FORMAT_SPECIFIER, "\u0001")
  end

  # --- needs_review reconciliation ----------------------------------------------------------------------


  # `xcstringstool sync` does NOT reconcile an existing key whose English source VALUE changed: it leaves
  # both the stored English value and the affected translations untouched (verified — source "Settings" →
  # "Preferences" left en="Settings" and fr="translated"). The in-Xcode build does this reconciliation; the
  # standalone CLI does not. This closes that gap: where the freshly-extracted English differs from what the
  # catalog stores, it updates the English value and flips that key's translations from `translated` to
  # `needs_review` (so the AI/human pipeline re-checks them).
  #
  # Out of scope here (handled elsewhere): English-as-key strings — editing their text changes the KEY, which
  # sync already handles as new/stale; and plural entries, whose English is itself a plural variation, so
  # `reconcile_entry!` bails (no flat English `stringUnit`) — those live in the separate plurals catalog.
  # Translation-side device/width variations of a regular string ARE reconciled (see `string_units`).
  #
  # @param catalog [Hash] parsed `.xcstrings`, mutated in place
  # @param current_en [Hash{String=>String}] key => freshly-extracted English value
  # @return [Array<String>] keys that were reconciled (English updated + translations re-flagged)
  def reconcile_source_changes!(catalog, current_en)
    (catalog['strings'] || {}).filter_map do |key, entry|
      key if reconcile_entry!(entry, current_en[key])
    end
  end

  # Reconcile one entry against its freshly-extracted English value. Returns the entry (truthy) if it
  # changed, nil otherwise — matching the Ruby bang-method convention (cf. String#gsub!).
  def reconcile_entry!(entry, new_value)
    return if new_value.nil?

    english = entry.dig('localizations', 'en', 'stringUnit')
    return if english.nil? || english['value'] == new_value

    english['value'] = new_value
    flag_translations_for_review!(entry['localizations'])
    entry
  end

  def flag_translations_for_review!(localizations)
    localizations.each do |locale, body|
      next if locale == 'en' || body.nil?

      string_units(body).each do |unit|
        unit['state'] = 'needs_review' if unit['state'] == 'translated'
      end
    end
  end

  # All stringUnits in a localization body, whether stored flat (`stringUnit`) or nested under one or more
  # `variations` (a regular string's translation can be varied by device/width, and variations can nest).
  # Returns the unit hashes themselves so a caller can flip their `state` in place — a single top-level
  # `body['stringUnit']` lookup would miss the varied leaves entirely.
  def string_units(node)
    return [] unless node.is_a?(Hash)

    units = []
    units << node['stringUnit'] if node['stringUnit'].is_a?(Hash)
    variations = node['variations']
    if variations.is_a?(Hash)
      variations.each_value do |cases|
        next unless cases.is_a?(Hash)

        cases.each_value { |child| units.concat(string_units(child)) }
      end
    end
    units
  end
end
