# frozen_string_literal: true

require 'json'
require 'nokogiri'

# Logic for the String Catalog ⇄ GlotPress plural pipeline. Plain Ruby with no fastlane dependencies, so it's
# unit-testable directly — the lanes in `localization_plurals.rb` call into it.
#
# Plurals are authored in a String Catalog (`Plurals.xcstrings`, English `one`/`other`).
# Each plural FORM is carried through GlotPress as an independent flat string keyed
# `<catalog-key>|==|plural.<cldr-category>` — the same id Apple's `xcodebuild -exportLocalizations`
# uses. Translations fold back into the catalog JSON using a per-locale CLDR category map that the reverse
# derives from Apple's exporter at fold time (a throwaway one-plural project — categories are a locale property).
module PluralStrings
  XLIFF_NS = { 'x' => 'urn:oasis:names:tc:xliff:document:1.2' }.freeze
  INFIX = '|==|plural.'
  CLDR_ORDER = %w[zero one two few many other].freeze

  module_function

  # The CLDR category encoded in a flat key, e.g. "posts.count|==|plural.few" => "few". Splits on the full
  # INFIX (not the bare "plural." substring) so a catalog key that itself contains "plural." — e.g.
  # "editor.plural.count" — still yields the trailing category rather than a garbled mid-key slice.
  def category_for(flat_key)
    flat_key.split(INFIX, 2).last
  end

  def plural_key?(key)
    key.include?(INFIX)
  end

  # Build the flat English originals from a parsed String Catalog.
  #
  # @param catalog [Hash] parsed `.xcstrings` JSON
  # @param categories [Array<String>] CLDR categories to emit per key (the union over ship locales)
  # @return [Hash{String=>Hash}] "<key>|==|plural.<cat>" => { value: <english>, comment: <dev note> }
  def flat_originals(catalog, categories)
    source = catalog['sourceLanguage'] || 'en'
    out = {}
    (catalog['strings'] || {}).each do |key, body|
      plural = body.dig('localizations', source, 'variations', 'plural')
      next unless plural # skip non-plural catalog entries

      other = plural.dig('other', 'stringUnit', 'value')
      categories.each do |cat|
        # English fallback for categories English itself doesn't distinguish (zero/two/few/many).
        value = plural.dig(cat, 'stringUnit', 'value') || other
        out["#{key}#{INFIX}#{cat}"] = { value: value, comment: plural_comment(body['comment'], cat) }
      end
    end
    out
  end

  # The dev note plus an explicit CLDR-category cue: every flat variant shares the same dev comment (and, for
  # categories English doesn't distinguish, the same English source), so the category is the only signal left.
  def plural_comment(note, category)
    [note, "Plural category: #{category}."].compact.reject(&:empty?).join(' ')
  end
  private_class_method :plural_comment

  # Plural keys whose source-language `other` form is missing or empty. `other` is the CLDR catch-all every
  # locale requires, and the form all not-otherwise-distinguished categories fall back to in `flat_originals`,
  # so a plural lacking it serializes to EMPTY GlotPress originals. The forward lane fails on these rather than
  # uploading empties (the catalog is hand-authored JSON, so Xcode's editor invariant doesn't guard it).
  def plural_keys_missing_other(catalog)
    source = catalog['sourceLanguage'] || 'en'
    (catalog['strings'] || {}).filter_map do |key, body|
      plural = body.dig('localizations', source, 'variations', 'plural')
      key if plural && plural.dig('other', 'stringUnit', 'value').to_s.empty?
    end
  end

  # Serialize entries to legacy (text) `.strings`. Accepts { key => "value" } or
  # { key => { value:, comment: } }. NOTE: emits text format (not XML/binary plist),
  # which the existing `ios_merge_strings_files` requires.
  def serialize_legacy_strings(entries)
    out = +''
    entries.each do |key, v|
      value = v.is_a?(Hash) ? v[:value] : v
      comment = v.is_a?(Hash) ? v[:comment] : nil
      out << "/* #{comment} */\n" if comment && !comment.empty?
      out << %(#{quote(key)} = #{quote(value)};\n\n)
    end
    out
  end

  # Per-locale CLDR category sets, read from exported skeleton XLIFFs (one `<locale>.xliff` per ship locale).
  # Apple owns the truth; the reverse derives this at fold time from a throwaway-fixture export.
  # @return [Hash{String=>Array<String>}] locale => categories (CLDR order).
  def categories_by_locale_from_skeletons(xliff_paths)
    xliff_paths.each_with_object({}) do |path, acc|
      cats = Nokogiri::XML(File.read(path)).xpath('//x:trans-unit', XLIFF_NS).filter_map do |tu|
        id = tu['id'].to_s
        category_for(id) if plural_key?(id)
      end
      acc[File.basename(path, '.xliff')] = cldr_sort(cats.uniq) unless cats.empty?
    end
  end

  # REVERSE (build-free): fold downloaded flat plural translations back into the catalog's per-locale plural
  # variations — the inverse of `flat_originals`. For each plural key and target locale, emit exactly the
  # categories that locale needs (per `categories_by_locale`), filling each with `human ?? AI ?? English`.
  # Human cells are `translated`; AI / English-fallback cells are `needs_review` (machine output to re-check).
  # `ai_translator` is optional and may return nil (the floor falls through to English). Mutates `catalog`;
  # returns the count of (key, locale) variations written.
  #
  # @param categories_by_locale [Hash{String=>Array<String>}] locale => CLDR categories it needs
  # @param translations_by_locale [Hash{String=>Hash{String=>String}}] locale => { "<key>|==|plural.<cat>" => value }
  def fold_translations!(catalog, categories_by_locale:, translations_by_locale:, ai_translator: nil)
    source = catalog['sourceLanguage'] || 'en'
    ctx = FoldContext.new(source, categories_by_locale.reject { |locale, _| locale == source }, translations_by_locale, ai_translator)
    (catalog['strings'] || {}).sum { |key, body| fold_entry!(body, key, ctx) }
  end

  # --- internal -------------------------------------------------------------

  FoldContext = Struct.new(:source, :targets, :translations, :ai)
  PluralEntry = Struct.new(:key, :comment, :plural)
  private_constant :FoldContext, :PluralEntry

  # Fold one catalog entry across all target locales; returns the number of locales written (0 if not a plural).
  def fold_entry!(body, key, ctx)
    plural = body.dig('localizations', ctx.source, 'variations', 'plural')
    return 0 unless plural

    entry = PluralEntry.new(key, body['comment'], plural)
    ctx.targets.each { |locale, cats| body['localizations'][locale] = plural_variation(entry, cats, ctx.translations[locale] || {}, ctx.ai, locale) }
    ctx.targets.size
  end
  private_class_method :fold_entry!

  def cldr_sort(categories)
    categories.sort_by { |c| CLDR_ORDER.index(c) || CLDR_ORDER.length }
  end
  private_class_method :cldr_sort

  # One locale's plural variation hash: { 'variations' => { 'plural' => { <cat> => stringUnit } } }.
  def plural_variation(entry, cats, human, ai_translator, locale)
    forms = cats.to_h { |cat| [cat, fold_cell(entry, cat, human, ai_translator, locale)] }
    { 'variations' => { 'plural' => forms } }
  end
  private_class_method :plural_variation

  # One target stringUnit for (entry, cat, locale): human ?? AI ?? English source; state reflects provenance
  # (human => translated; AI / English fallback => needs_review).
  def fold_cell(entry, cat, human, ai_translator, locale)
    id = "#{entry.key}#{INFIX}#{cat}"
    human_value = human[id]
    return cell('translated', human_value) unless human_value.to_s.empty?

    english = entry.plural.dig(cat, 'stringUnit', 'value') || entry.plural.dig('other', 'stringUnit', 'value')
    ai = ai_translator&.call(id: id, source: english, category: cat, note: entry.comment, locale: locale)
    cell('needs_review', ai.to_s.empty? ? english : ai)
  end
  private_class_method :fold_cell

  def cell(state, value)
    { 'stringUnit' => { 'state' => state, 'value' => value } }
  end
  private_class_method :cell

  # --- internal -------------------------------------------------------------

  def quote(str)
    inner = str.to_s.gsub(/(["\\])/) { "\\#{Regexp.last_match(1)}" }
    %("#{inner}")
  end
  private_class_method :quote
end
