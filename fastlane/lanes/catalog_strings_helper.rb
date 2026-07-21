# frozen_string_literal: true

require_relative 'translation_validator'

# Reverse fold for regular (non-plural) strings into a String Catalog (`Localizable.xcstrings`) — the catalog
# analogue of `PluralStrings.fold_translations!`. For each translatable key and target locale it sets the
# stringUnit to `human ?? existing-machine ?? AI ?? English` (human => `translated`; machine / English fallback
# => `needs_review`). Plain Ruby with no fastlane / gem dependencies, so it's unit-testable directly — the lane
# in `localization_catalog.rb` calls into it.
#
# REUSE-AWARE: a cell that already holds a valid translation (value present, not just the English source, still
# passing the placeholder gate) is kept untouched, whatever its state. Primarily this persists MACHINE cells —
# the whole point of folding into the catalog rather than the legacy `.strings`: the `needs_review` state IS the
# store (no side-store), so re-runs only translate genuinely-new gaps, and a human translation from GlotPress
# supersedes a kept cell automatically on the next fold. The reuse is deliberately state-agnostic, not
# machine-only — see reusable_cell.
#
# This module holds the pure logic behind the localize lanes — the fold, the per-locale run summary, and the
# `locales:` spec resolution — so the lane keeps only the fastlane/UI/file-IO glue and the whole thing lifts
# cleanly into release-toolkit later.
module CatalogStrings # rubocop:disable Metrics/ModuleLength -- the fold, its summary, and locale resolution over one catalog structure
  module_function

  # Mutates `catalog`; returns the count of (key, locale) cells written.
  #
  # @param translations_by_locale [Hash{String=>Hash{String=>String}}] locale => { key => human value }, from
  #   the downloaded `.lproj/Localizable.strings`.
  # @param locales [Array<String>] target locales to fold (the source locale is skipped).
  # @param ai_translator [#call] `call(entries, locale) => { key => translation }`, entries being
  #   `[{ key:, source:, comment: }]`. Optional; nil ⇒ the fill rung is skipped (English fallback).
  def fold_translations!(catalog, translations_by_locale:, locales:, ai_translator: nil)
    source = catalog['sourceLanguage'] || 'en'
    sources = translatable_sources(catalog, source)
    (locales - [source]).sum do |locale|
      fold_locale!(catalog, locale, sources, translations_by_locale[locale] || {}, ai_translator)
    end
  end

  # A per-locale summary of a folded catalog, so a run can be eyeballed from the log without opening the file.
  # For each target locale, counts how many entries are human translations (`translated`), machine translations
  # (`needs_review` differing from English), and still English (`needs_review` equal to the English source),
  # plus up to `sample_limit` example machine translations to spot-check quality. Reads the catalog as-is, so it
  # also summarizes a catalog from a prior run.
  #
  # Returns { locale => { human:, machine:, english:, samples: [{ key:, english:, translation: }] } }.
  def summarize(catalog, locales:, sample_limit: 5)
    source = catalog['sourceLanguage'] || 'en'
    strings = catalog['strings'] || {}
    (locales - [source]).to_h do |locale|
      [locale, summarize_locale(strings, locale, source, sample_limit)]
    end
  end

  def summarize_locale(strings, locale, source, sample_limit)
    tally = { human: 0, machine: 0, english: 0, samples: [] }
    strings.each do |key, body|
      english = body.dig('localizations', source, 'stringUnit', 'value') || key
      classify_cell!(tally, body.dig('localizations', locale, 'stringUnit'), english, key, sample_limit)
    end
    tally
  end
  private_class_method :summarize_locale

  # Fold one cell into the running tally: human (`translated`), still-English (`needs_review` == English), or
  # machine (`needs_review` differing from English, a few kept as samples). Cells with any other state, or none
  # for this locale, don't count.
  def classify_cell!(tally, unit, english, key, sample_limit)
    return if unit.nil?

    case unit['state']
    when 'translated'
      tally[:human] += 1
    when 'needs_review'
      if unit['value'] == english
        tally[:english] += 1
      else
        tally[:machine] += 1
        tally[:samples] << { key: key, english: english, translation: unit['value'] } if tally[:samples].size < sample_limit
      end
    end
  end
  private_class_method :classify_cell!

  # Format a `summarize` result into log lines for eyeballing a run — one headline per locale plus a few
  # indented sample machine translations. Pure; the lane just prints these.
  def summary_lines(summary_by_locale)
    summary_by_locale.flat_map { |locale, tally| locale_summary_lines(locale, tally) }
  end

  def locale_summary_lines(locale, tally)
    human, machine, english = tally.values_at(:human, :machine, :english)
    headline = "  #{locale}: #{human + machine + english} entries — #{human} human, #{machine} machine, #{english} still English"
    [headline, *tally[:samples].map { |ex| "      #{ex[:key]}: #{ex[:english].inspect} → #{ex[:translation].inspect}" }]
  end
  private_class_method :locale_summary_lines

  # Resolve a `locales:` spec (comma-separated lproj codes, e.g. "fr,de") against the full ship-locale map. A
  # blank spec means all locales. Returns { selected: {glotpress=>lproj}, unknown: [codes matching nothing] } —
  # the caller decides what to do (error if `selected` is empty, warn about `unknown`). Pure; no fastlane/UI.
  def select_locales(spec, locale_map)
    return { selected: locale_map, unknown: [] } if spec.to_s.strip.empty?

    # lproj codes are mixed-case (pt-BR, zh-Hans, en-GB); compare on downcased codes so a lowercased spec
    # (e.g. `locales:pt-br`) resolves instead of being silently dropped as unknown.
    wanted = spec.to_s.split(',').map { |code| code.strip.downcase }.reject(&:empty?)
    selected = locale_map.select { |_glotpress, lproj| wanted.include?(lproj.downcase) }
    { selected: selected, unknown: wanted - selected.values.map(&:downcase) }
  end

  # { key => { source:, comment: } } for every translatable key — its explicit English value, or the key itself
  # for key-as-source strings (genstrings's convention, where the English text *is* the key). Entries flagged
  # `shouldTranslate: false`, and entries whose English is not a flat `stringUnit` (device/width variations or a
  # plural), are skipped — see `source_value`.
  def translatable_sources(catalog, source)
    (catalog['strings'] || {}).each_with_object({}) do |(key, body), acc|
      next if body['shouldTranslate'] == false

      value = source_value(body, source, key)
      acc[key] = { source: value, comment: body['comment'] } unless value.to_s.empty?
    end
  end
  private_class_method :translatable_sources

  # The English source text to translate for one entry, or nil to skip it.
  #
  # A key-as-source string (no `source` localization at all) uses the key itself as its English text —
  # genstrings's convention. But an entry whose `source` localization DOES exist while storing its value under
  # `variations` (a device/width-varied regular string) or a plural, rather than a flat `stringUnit`, is NOT
  # key-as-source: falling back to the key there would ship the reverse-DNS key to the translator as if it were
  # English and write the mangled result back as a real translation, corrupting a valid entry. We can't fold a
  # varied/plural source into one flat translation, so we skip it — matching `CatalogHelper.reworded_keys`,
  # which only reads the flat `en` `stringUnit` value (proper translation of varied regular strings is a
  # separate feature).
  def source_value(body, source, key)
    localization = body.dig('localizations', source)
    return key if localization.nil? # key-as-source: no explicit English, so the key IS the English text

    localization.dig('stringUnit', 'value') # flat English value, or nil to skip a non-flat (varied/plural) entry
  end
  private_class_method :source_value

  # Fold one locale: resolve the human/reused cells, translate only what's left, write them all. Returns the
  # number of cells written.
  def fold_locale!(catalog, locale, sources, human, ai_translator)
    plan = plan_locale(catalog, locale, sources, human)
    cells = plan[:cells].merge(machine_cells(plan[:fresh], translate(ai_translator, plan[:fresh], locale)))
    cells.each { |key, unit| set_cell!(catalog, key, locale, unit) }
    cells.size
  end
  private_class_method :fold_locale!

  # { key => machine stringUnit } for the fresh entries: the validated AI translation, or the English source as
  # a flagged fallback where the model returned nothing. Disjoint from the human/reused cells.
  def machine_cells(fresh, ai_reply)
    fresh.to_h { |entry| [entry[:key], ai_cell(ai_reply[entry[:key]], entry[:source])] }
  end
  private_class_method :machine_cells

  # Partition this locale's keys into ready `cells` ({ key => stringUnit }: human ⇒ translated, reusable machine
  # ⇒ kept) and `fresh` ([{ key:, source:, comment: }] needing the model).
  def plan_locale(catalog, locale, sources, human)
    cells = {}
    fresh = []
    sources.each do |key, info|
      source = info[:source]
      if (value = trusted_human(human[key], source, key, locale))
        cells[key] = cell('translated', value)
      elsif (reused = reusable_cell(catalog, key, locale, source))
        cells[key] = reused
      else
        fresh << { key: key, source: source, comment: info[:comment] }
      end
    end
    { cells: cells, fresh: fresh }
  end
  private_class_method :plan_locale

  # The `human` rung of `human ?? AI ?? English`: the GlotPress value to ship as `translated`, or nil to fall
  # through to the machine/English rungs. A blank value is dropped silently; a present-but-placeholder-broken one
  # must NOT ship — it would send a format-argument mismatch to runtime (wrong vararg → crash) in a locale CI
  # can't read — so it's rejected and surfaced. Uses the same TranslationValidator gate reusable_cell and the AI
  # tier apply, not a second implementation.
  def trusted_human(value, source, key, locale)
    return nil if value.to_s.strip.empty?
    return value if TranslationValidator.placeholders_match?(source, value)

    # Surface the rejection so a broken GlotPress string gets fixed rather than silently downgraded to machine.
    warn "CatalogStrings: rejected #{locale} human translation for #{key.inspect} — " \
         "#{TranslationValidator.mismatch_reason(source, value)}; using machine/English instead."
    nil
  end
  private_class_method :trusted_human

  # The existing cell to keep as-is, or nil to re-fill it: a stringUnit whose value is present, isn't just the
  # English source (an unfilled English fallback we should retry), and still satisfies the placeholder gate.
  #
  # Intentionally state-agnostic — unlike the plural sibling PluralStrings.kept_ai_value, which gates on
  # `needs_review`. Besides persisting machine (`needs_review`) cells across runs, this also keeps a human
  # (`translated`) cell whose GlotPress source later vanishes (a translation rejected/reverted upstream with no
  # replacement): the last-approved text is frozen rather than overwritten with a machine guess, and a current
  # GlotPress value supersedes it via trusted_human on the next fold. The only cost is a stale `translated`
  # label until then, in a catalog nothing ships yet.
  def reusable_cell(catalog, key, locale, source)
    unit = catalog.dig('strings', key, 'localizations', locale, 'stringUnit')
    return nil if unit.nil?

    value = unit['value'].to_s
    # On `value == source`: if the saved translation is just the English word again, we treat it as "not really
    # translated yet" and translate it once more next time. One quirk falls out of this — a word that happens to
    # be the same in the other language (like "OK", which stays "OK") looks exactly like that case, so it gets
    # translated again on every run instead of being kept. It's a tiny bit of repeated work, harmless, and it
    # goes away as soon as a human translates that word.
    return nil if value.empty? || value == source || !TranslationValidator.placeholders_match?(source, value)

    unit
  end
  private_class_method :reusable_cell

  def translate(ai_translator, fresh, locale)
    return {} if ai_translator.nil? || fresh.empty?

    ai_translator.call(fresh, locale) || {}
  end
  private_class_method :translate

  # A machine cell: the validated AI translation if present, else the English source as a flagged fallback.
  def ai_cell(translation, source)
    cell('needs_review', translation.to_s.empty? ? source : translation)
  end
  private_class_method :ai_cell

  def set_cell!(catalog, key, locale, unit)
    localizations = (catalog['strings'][key]['localizations'] ||= {})
    reject_varied_target!(localizations[locale], key, locale)
    localizations[locale] = { 'stringUnit' => unit }
  end
  private_class_method :set_cell!

  # The fold only ever produces flat `stringUnit` cells. If a target locale already holds a `variations`
  # (device/width/plural) or `substitutions` structure, overwriting it with one flat value would silently
  # destroy a translation the fold can't rebuild — and nothing in this pipeline should ever produce a varied
  # target cell in the first place. So this isn't something to paper over: crash loudly, as a signal that an
  # upstream assumption is wrong (a hand-edited catalog, or a new feature that outgrew the flat-only fold).
  def reject_varied_target!(existing, key, locale)
    return unless existing.is_a?(Hash) && (existing.key?('variations') || existing.key?('substitutions'))

    raise "CatalogStrings: the #{locale} cell for #{key.inspect} holds a variations/substitutions structure, but " \
          'the fold only handles flat strings — refusing to overwrite it with a flat translation. This shape ' \
          'should never occur here, so something upstream is wrong.'
  end
  private_class_method :reject_varied_target!

  def cell(state, value)
    { 'state' => state, 'value' => value }
  end
  private_class_method :cell
end
