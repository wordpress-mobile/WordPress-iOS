# frozen_string_literal: true

require 'json'

# Logic for the String Catalog ⇄ GlotPress plural pipeline. Plain Ruby with no fastlane dependencies, so it's
# unit-testable directly — the lanes in `localization_plurals.rb` call into it.
#
# Plurals are authored in a String Catalog (`Plurals.xcstrings`, English `one`/`other`).
# Each plural FORM is carried through GlotPress as an independent flat string keyed
# `<catalog-key>|==|plural.<cldr-category>` — the same id Apple's `xcodebuild -exportLocalizations`
# uses. Translations fold back into the catalog JSON using a per-locale CLDR category map that the reverse
# derives from Apple's exporter at fold time (a throwaway one-plural project — categories are a locale property).
module PluralStrings # rubocop:disable Metrics/ModuleLength -- one cohesive pipeline of small, single-purpose, individually-documented helpers
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
    require 'nokogiri' # only the exporter-skeleton path needs it; kept lazy so the pure fold has no gem dependency
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
  # Mutates `catalog`; returns the count of (key, locale) variations written. Idempotent for machine output: a
  # reusable AI cell from a prior fold (needs_review, not an English fallback) is carried over rather than
  # re-translated, so an unchanged re-run neither re-calls the model nor churns the staged text.
  #
  # `ai_translator` (optional) is invoked ONCE per (key, locale) with the whole form-set — not per cell — so
  # the model keeps one consistent stem across the forms; a per-category call lets it drift between synonyms
  # (e.g. Polish słowo -> wyrazy -> słów). It is called as:
  #   ai_translator.call(english_forms:, categories:, locale:, note:, anchors:) => { <cat> => translation }
  # where `anchors` are the forms already in hand — human translations plus reusable machine cells kept from a
  # prior fold — passed as fixed context to stay consistent with, and excluded from what's asked for. It may
  # return nil / {} or omit any category — those cells fall through to English. `AITranslator#translate_plural`
  # implements this contract directly, so wiring the live tier is `ai_translator: translator.method(:translate_plural)`.
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
  # One (key, locale) fold slot: the categories the locale needs, its downloaded human forms, and the existing
  # catalog localization (nil on first fold) whose reusable machine cells make the fold idempotent.
  Slot = Struct.new(:locale, :cats, :human, :existing)
  private_constant :FoldContext, :PluralEntry, :Slot

  # Fold one catalog entry across all target locales; returns the number of locales written (0 if not a plural).
  def fold_entry!(body, key, ctx)
    plural = body.dig('localizations', ctx.source, 'variations', 'plural')
    return 0 unless plural

    entry = PluralEntry.new(key, body['comment'], plural)
    locals = body['localizations']
    ctx.targets.each { |locale, cats| locals[locale] = plural_variation(entry, slot_for(ctx, locals, locale, cats), ctx.ai) }
    ctx.targets.size
  end
  private_class_method :fold_entry!

  # The per-(key, locale) fold inputs: the locale's needed categories, its downloaded human forms, and the
  # existing catalog localization (nil on first fold) whose reusable machine cells keep the fold idempotent.
  def slot_for(ctx, locals, locale, cats)
    Slot.new(locale, cats, ctx.translations[locale] || {}, locals[locale])
  end
  private_class_method :slot_for

  def cldr_sort(categories)
    categories.sort_by { |c| CLDR_ORDER.index(c) || CLDR_ORDER.length }
  end
  private_class_method :cldr_sort

  # One locale's plural variation hash: { 'variations' => { 'plural' => { <cat> => stringUnit } } }. Resolve the
  # English and human forms first, carry over any reusable machine cells from the previous fold (so re-runs are
  # idempotent), ask the AI tier (once, whole form-set) for whatever's STILL missing, then write each cell as
  # human ?? AI ?? English.
  def plural_variation(entry, slot, ai_translator)
    cats = slot.cats
    english_forms = english_forms_for(entry.plural, cats)
    human_forms = human_forms_for(entry.key, cats, slot.human)
    kept_ai = kept_ai_forms(slot.existing, cats, human_forms, english_forms)
    anchors = human_forms.merge(kept_ai)
    ai_forms = kept_ai.merge(fresh_ai_forms(ai_translator, entry, slot, english_forms, anchors))

    forms = cats.to_h { |cat| [cat, fold_cell(cat, human_forms, ai_forms, english_forms)] }
    { 'variations' => { 'plural' => forms } }
  end
  private_class_method :plural_variation

  # Machine cells from the previous fold worth reusing, keyed by CLDR category — the crux of an idempotent
  # re-run. A cell is kept only when it holds a real machine translation (needs_review, non-empty, and not just
  # the English fallback) for a category the current download hasn't since covered with a human form. Kept cells
  # both anchor the AI request and pass straight through, so an unchanged fold never re-calls the (billable,
  # non-deterministic) model nor churns needs_review text a reviewer may be mid-review of. English-fallback
  # cells (the AI declined last time) are deliberately NOT kept, so a transient outage is retried next run.
  def kept_ai_forms(existing, cats, human_forms, english_forms)
    prior = existing.is_a?(Hash) ? existing.dig('variations', 'plural') : nil
    return {} unless prior.is_a?(Hash)

    cats.each_with_object({}) do |cat, acc|
      value = kept_ai_value(prior[cat], english_forms[cat])
      acc[cat] = value if value && !human_forms.key?(cat)
    end
  end
  private_class_method :kept_ai_forms

  # A previous cell's value if it's a reusable machine translation (needs_review and not merely the English
  # fallback), else nil so the category is re-filled.
  def kept_ai_value(prior_cell, english)
    unit = prior_cell.is_a?(Hash) ? prior_cell['stringUnit'] : nil
    return nil unless unit.is_a?(Hash) && unit['state'] == 'needs_review'

    value = unit['value'].to_s
    value unless value.empty? || value == english
  end
  private_class_method :kept_ai_value

  # The AI tier's fresh output for the categories still missing after human + kept-machine forms — or {} when
  # there's no translator or nothing is missing, so the fold itself (not just the injected callable) skips a
  # needless, billable request when every form is already in hand.
  def fresh_ai_forms(ai_translator, entry, slot, english_forms, anchors)
    return {} if ai_translator.nil? || (slot.cats - anchors.keys).empty?

    ai_translator.call(english_forms: english_forms, categories: slot.cats, locale: slot.locale, note: entry.comment, anchors: anchors) || {}
  end
  private_class_method :fresh_ai_forms

  # English value per needed category — the form's own English, or the `other` value both for categories English
  # doesn't itself distinguish (zero/two/few/many) AND for any form left blank in the source. CLDR guarantees a
  # non-empty `other` (the forward lane enforces it via `plural_keys_missing_other`), so this never yields blank.
  def english_forms_for(plural, cats)
    other = plural.dig('other', 'stringUnit', 'value')
    cats.to_h do |cat|
      own = plural.dig(cat, 'stringUnit', 'value')
      [cat, own.to_s.empty? ? other : own]
    end
  end
  private_class_method :english_forms_for

  # Human (GlotPress) translations present for this key, keyed by CLDR category. These ship as `translated` and
  # double as the AI request's anchors so the machine-filled forms stay consistent with the human's word choice.
  # A blank-or-whitespace-only value isn't a real translation — it's dropped, so it neither ships as `translated`
  # nor anchors the request (the category falls through to AI / English instead).
  def human_forms_for(key, cats, human)
    cats.each_with_object({}) do |cat, acc|
      value = human["#{key}#{INFIX}#{cat}"]
      acc[cat] = value unless value.to_s.strip.empty?
    end
  end
  private_class_method :human_forms_for

  # One target stringUnit for a category: human ?? AI ?? English; state reflects provenance (human =>
  # translated; AI / English fallback => needs_review, i.e. machine output to re-check).
  def fold_cell(cat, human_forms, ai_forms, english_forms)
    human = human_forms[cat]
    return cell('translated', human) unless human.to_s.empty?

    ai = ai_forms[cat]
    cell('needs_review', ai.to_s.empty? ? english_forms[cat] : ai)
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
