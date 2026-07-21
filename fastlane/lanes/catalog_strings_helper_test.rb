# frozen_string_literal: true

# Pure-Ruby unit suite for CatalogStrings.fold_translations! — the regular-string reverse fold into
# Localizable.xcstrings. Run directly: `ruby fastlane/lanes/catalog_strings_helper_test.rb`. No bundle / network
# (the AI tier is a stub lambda). Fixtures under `fixtures/` are real `.xcstrings` documents validated with
# `xcstringstool print`, loaded here as plain JSON — the same parse the lane does.
require 'minitest/autorun'
require 'json'
require 'stringio'
require_relative 'catalog_strings_helper'

# Exercises provenance (human => translated; machine / English fallback => needs_review), the reuse rule (a
# valid existing machine cell is kept and not re-translated; an English-fallback or placeholder-broken cell is
# retried), key-as-source handling, the variations/plural skip (English stored under `variations` is NOT
# translated from its key), shouldTranslate, and the batched per-locale AI call.
class CatalogStringsFoldTest < Minitest::Test # rubocop:disable Metrics/ClassLength -- exhaustive scenario coverage
  def unit(state, value)
    { 'stringUnit' => { 'state' => state, 'value' => value } }
  end

  # A catalog entry with an explicit English value, optional comment, and optional pre-existing localizations.
  def entry(english, comment: nil, locs: {})
    body = { 'localizations' => { 'en' => unit('translated', english) }.merge(locs) }
    body['comment'] = comment if comment
    body
  end

  def catalog(strings)
    { 'sourceLanguage' => 'en', 'version' => '1.0', 'strings' => strings }
  end

  def cell(cat, key, locale)
    cat.dig('strings', key, 'localizations', locale, 'stringUnit')
  end

  # An AI stub returning `reply` ({ key => translation }), recording each (entries, locale) call.
  def recording_translator(reply:, calls:)
    lambda do |entries, locale|
      calls << { entries: entries, locale: locale }
      reply
    end
  end

  def fold(cat, translations: {}, locales: %w[en fr], ai_translator: nil)
    CatalogStrings.fold_translations!(cat, translations_by_locale: translations, locales: locales, ai_translator: ai_translator)
  end

  # Parse a real `.xcstrings` fixture from `fixtures/` (xcstringstool-validated) exactly as the lane does.
  def load_fixture(name)
    JSON.parse(File.read(File.join(__dir__, 'fixtures', name)))
  end

  # The keys the AI stub was actually asked to translate, across all recorded calls.
  def translated_keys(calls)
    calls.flat_map { |c| c[:entries].map { |e| e[:key] } }
  end

  # Runs the block with $stderr captured, returning what it wrote (the fold surfaces rejected humans via warn).
  def capture_stderr
    original = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original
  end

  def test_human_translation_is_used_and_marked_translated
    cat = catalog('a' => entry('Save'))
    written = fold(cat, translations: { 'fr' => { 'a' => 'Enregistrer' } })

    assert_equal 1, written
    assert_equal({ 'state' => 'translated', 'value' => 'Enregistrer' }, cell(cat, 'a', 'fr'))
  end

  # A human translation that reorders a non-positional source (%@ … %@) via positional specifiers (%2$@ … %1$@)
  # is valid at runtime — String(format:) honors positional specifiers regardless of the source's shape — and is
  # the standard iOS reordering pattern for RTL / word-order-differing locales. It must ship as `translated`, NOT
  # be rejected by the placeholder gate and downgraded to machine/English. This is the user-facing half of the
  # TranslationValidator regression (see translation_validator_test.rb): 23 key-as-source strings across 34
  # locales (513 currently-shipping cells) do exactly this, e.g. ar "%@ of %@ used on your site" folds to
  # "%1$@ من %2$@ على موقعك". With no AI tier here, the rejected human currently degrades to English (needs_review).
  def test_reordered_human_translation_of_a_non_positional_source_is_kept_as_translated
    cat = catalog('a' => entry('%@ of %@ used'))
    capture_stderr { fold(cat, translations: { 'fr' => { 'a' => '%2$@ sur %1$@ utilisés' } }) }

    assert_equal({ 'state' => 'translated', 'value' => '%2$@ sur %1$@ utilisés' }, cell(cat, 'a', 'fr'),
                 'a reordered human translation must ship as translated, not be downgraded')
  end

  # A whitespace-only GlotPress value is not a real translation: it must not ship as `translated` — the key
  # should still reach the model and land as `needs_review`, same as if GlotPress had no value at all.
  def test_whitespace_only_human_value_is_treated_as_untranslated
    cat = catalog('a' => entry('Save'))
    calls = []
    fold(cat, translations: { 'fr' => { 'a' => '   ' } }, ai_translator: recording_translator(reply: { 'a' => 'Enregistrer' }, calls: calls))

    assert_equal(['a'], calls.first[:entries].map { |e| e[:key] }, 'a blank human value must not be treated as translated')
    assert_equal({ 'state' => 'needs_review', 'value' => 'Enregistrer' }, cell(cat, 'a', 'fr'))
  end

  # A human value that drops/retypes a format specifier would crash at runtime if shipped as `translated`. It
  # must be REJECTED (same gate as machine cells) and surfaced, then fall through to the model — landing as
  # `needs_review`, never `translated`.
  def test_placeholder_broken_human_value_is_rejected_and_surfaced_not_shipped
    cat = catalog('a' => entry('%1$d posts'))
    calls = []
    warnings = capture_stderr do
      fold(cat, translations: { 'fr' => { 'a' => 'articles' } }, # %1$d dropped
                ai_translator: recording_translator(reply: { 'a' => '%1$d articles' }, calls: calls))
    end

    assert_equal(['a'], calls.first[:entries].map { |e| e[:key] }, 'a placeholder-broken human must fall through to the model, not ship')
    assert_equal({ 'state' => 'needs_review', 'value' => '%1$d articles' }, cell(cat, 'a', 'fr'))
    assert_match(/rejected fr human translation for "a"/, warnings)
  end

  # With the broken human rejected and no AI tier, the cell degrades to English (needs_review) — it must never
  # ship the crash-inducing human string.
  def test_placeholder_broken_human_value_with_no_ai_falls_back_to_english
    cat = catalog('a' => entry('%1$d posts'))
    capture_stderr { fold(cat, translations: { 'fr' => { 'a' => 'articles' } }) }

    assert_equal({ 'state' => 'needs_review', 'value' => '%1$d posts' }, cell(cat, 'a', 'fr'), 'a broken human degrades to English, never ships')
  end

  def test_ai_fills_missing_and_marks_needs_review
    cat = catalog('a' => entry('Save'))
    fold(cat, ai_translator: recording_translator(reply: { 'a' => 'Enregistrer' }, calls: []))

    assert_equal({ 'state' => 'needs_review', 'value' => 'Enregistrer' }, cell(cat, 'a', 'fr'))
  end

  def test_english_fallback_when_no_human_and_no_ai
    cat = catalog('a' => entry('Save'))
    fold(cat)

    assert_equal({ 'state' => 'needs_review', 'value' => 'Save' }, cell(cat, 'a', 'fr'))
  end

  def test_existing_machine_cell_is_reused_without_calling_the_model
    cat = catalog('a' => entry('Save', locs: { 'fr' => unit('needs_review', 'Enregistrer') }))
    calls = []
    fold(cat, ai_translator: recording_translator(reply: {}, calls: calls))

    assert_empty calls, 'a reusable machine cell must not trigger a model call'
    assert_equal({ 'state' => 'needs_review', 'value' => 'Enregistrer' }, cell(cat, 'a', 'fr'))
  end

  def test_english_fallback_cell_is_retried_not_reused
    # A prior cell whose value is just the English source was an unfilled fallback — retry it.
    cat = catalog('a' => entry('Save', locs: { 'fr' => unit('needs_review', 'Save') }))
    calls = []
    fold(cat, ai_translator: recording_translator(reply: { 'a' => 'Enregistrer' }, calls: calls))

    assert_equal(['a'], calls.first[:entries].map { |e| e[:key] })
    assert_equal({ 'state' => 'needs_review', 'value' => 'Enregistrer' }, cell(cat, 'a', 'fr'))
  end

  def test_placeholder_broken_cell_is_retried
    cat = catalog('a' => entry('%1$d posts', locs: { 'fr' => unit('needs_review', 'articles') }))
    fold(cat, ai_translator: recording_translator(reply: { 'a' => '%1$d articles' }, calls: []))

    assert_equal({ 'state' => 'needs_review', 'value' => '%1$d articles' }, cell(cat, 'a', 'fr'))
  end

  def test_present_but_empty_existing_cell_is_retried
    # A stored cell with an empty value isn't a real translation — and this is a distinct branch from the
    # no-localization first-fold path — so it must be retried, not passed through as-is.
    cat = catalog('a' => entry('Save', locs: { 'fr' => unit('needs_review', '') }))
    calls = []
    fold(cat, ai_translator: recording_translator(reply: { 'a' => 'Enregistrer' }, calls: calls))

    assert_equal(['a'], calls.first[:entries].map { |e| e[:key] }, 'an empty-value cell must be retried')
    assert_equal({ 'state' => 'needs_review', 'value' => 'Enregistrer' }, cell(cat, 'a', 'fr'))
  end

  def test_human_supersedes_existing_machine_cell
    cat = catalog('a' => entry('Save', locs: { 'fr' => unit('needs_review', 'old machine value') }))
    fold(cat, translations: { 'fr' => { 'a' => 'Enregistrer' } })

    assert_equal({ 'state' => 'translated', 'value' => 'Enregistrer' }, cell(cat, 'a', 'fr'))
  end

  def test_key_as_source_string_uses_the_key_as_english
    cat = catalog('%1$@ on %2$@' => {}) # no English localization: the key is the source
    calls = []
    fold(cat, ai_translator: recording_translator(reply: {}, calls: calls))

    assert_equal '%1$@ on %2$@', calls.first[:entries].first[:source]
    assert_equal({ 'state' => 'needs_review', 'value' => '%1$@ on %2$@' }, cell(cat, '%1$@ on %2$@', 'fr'))
  end

  def test_key_as_source_string_reuses_existing_machine_cell
    # Key-as-source (source resolves to the key itself) combined with a valid pre-existing machine cell:
    # exercises reusable_cell's `value == source` check with source threaded as the key, and confirms the cell
    # is kept rather than re-translated.
    cat = catalog('%1$@ on %2$@' => { 'localizations' => { 'fr' => unit('needs_review', '%1$@ le %2$@') } })
    calls = []
    fold(cat, ai_translator: recording_translator(reply: {}, calls: calls))

    assert_empty calls, 'a reusable cell on a key-as-source string must not trigger a model call'
    assert_equal({ 'state' => 'needs_review', 'value' => '%1$@ le %2$@' }, cell(cat, '%1$@ on %2$@', 'fr'))
  end

  # Regression: a regular string whose English is stored under `variations` (here per-device) has no flat
  # stringUnit. It must be SKIPPED — never translated from its reverse-DNS key — while the flat and
  # key-as-source entries in the same (xcstringstool-validated) catalog still fold with the right sources.
  def test_variations_shaped_english_is_skipped_not_translated_from_its_key
    cat = load_fixture('catalog_with_variations.xcstrings')
    original_en = cat.dig('strings', 'app.banner.tapToOpen', 'localizations', 'en')
    calls = []
    fold(cat, ai_translator: recording_translator(reply: {}, calls: calls))

    # The varied entry is absent; the flat and key-as-source entries fold with their correct English source.
    translated = calls.flat_map { |c| c[:entries] }.to_h { |e| [e[:key], e[:source]] }
    assert_equal({ 'app.button.save' => 'Save', '%1$@ on %2$@' => '%1$@ on %2$@' }, translated)
    # No fr cell is fabricated for the varied entry, and its English variations are left untouched.
    assert_nil cell(cat, 'app.banner.tapToOpen', 'fr'), 'a variations-shaped source must not get a folded cell'
    assert_same original_en, cat.dig('strings', 'app.banner.tapToOpen', 'localizations', 'en')
  end

  # The skip holds across re-runs, so a variations-shaped entry can never be re-submitted to the billable API
  # (the "re-translated forever" failure a key-derived English fallback would cause).
  def test_variations_shaped_english_is_never_rebilled_across_reruns
    cat = load_fixture('catalog_with_variations.xcstrings')
    calls = []
    translator = recording_translator(reply: { 'app.button.save' => 'Enregistrer' }, calls: calls)
    2.times { fold(cat, ai_translator: translator) }

    refute_includes translated_keys(calls), 'app.banner.tapToOpen'
  end

  # A flat English source whose TARGET cell was somehow authored with device variations is a shape the fold
  # can't handle — nothing in the pipeline produces it. It must CRASH loudly (a signal something is wrong), not
  # silently flatten the per-device translations and re-bill it.
  def test_fold_crashes_rather_than_clobber_a_varied_target_cell
    varied_fr = { 'variations' => { 'device' => { 'iphone' => unit('translated', 'Appuyez') } } }
    cat = catalog('a' => entry('Tap', locs: { 'fr' => varied_fr }))
    error = assert_raises(RuntimeError) do
      fold(cat, ai_translator: recording_translator(reply: { 'a' => 'Toucher' }, calls: []))
    end

    assert_match(%r{variations/substitutions}, error.message)
    assert_match(/"a"/, error.message, 'the crash names the offending key')
  end

  def test_should_translate_false_is_skipped
    cat = catalog(
      'a' => entry('Save'),
      'b' => entry('WordPress').merge('shouldTranslate' => false)
    )
    written = fold(cat)

    assert_equal 1, written
    assert_nil cell(cat, 'b', 'fr'), 'shouldTranslate:false entries get no translations'
  end

  def test_empty_catalog_folds_nothing
    cat = catalog({})
    calls = []
    assert_equal 0, fold(cat, ai_translator: recording_translator(reply: {}, calls: calls))
    assert_empty calls, 'an empty catalog must not call the model'
  end

  def test_all_untranslatable_catalog_folds_nothing
    cat = catalog(
      'a' => entry('WordPress').merge('shouldTranslate' => false),
      'b' => entry('Jetpack').merge('shouldTranslate' => false)
    )
    calls = []
    assert_equal 0, fold(cat, ai_translator: recording_translator(reply: {}, calls: calls))
    assert_empty calls, 'an all-untranslatable catalog must not call the model'
  end

  def test_source_locale_is_not_folded
    cat = catalog('a' => entry('Save'))
    original_en = cat.dig('strings', 'a', 'localizations', 'en')
    fold(cat, locales: %w[en fr])

    assert_same original_en, cat.dig('strings', 'a', 'localizations', 'en')
  end

  def test_ai_called_once_per_locale_with_batched_entries
    cat = catalog('a' => entry('Save'), 'b' => entry('Posts: %1$d', comment: 'count'))
    calls = []
    fold(cat, ai_translator: recording_translator(reply: { 'a' => 'Enregistrer', 'b' => 'Articles : %1$d' }, calls: calls))

    assert_equal 1, calls.size
    assert_equal 'fr', calls.first[:locale]
    assert_equal(
      [{ key: 'a', source: 'Save', comment: nil }, { key: 'b', source: 'Posts: %1$d', comment: 'count' }],
      calls.first[:entries]
    )
  end

  def test_partial_batched_ai_reply_falls_back_per_key
    # The model answers one key of a batch but omits the other — the omitted key falls back to English
    # (needs_review), the answered key is used. The most realistic live-AI failure mode for a large batch.
    cat = catalog('a' => entry('Save'), 'b' => entry('Delete'))
    fold(cat, ai_translator: recording_translator(reply: { 'a' => 'Enregistrer' }, calls: []))

    assert_equal({ 'state' => 'needs_review', 'value' => 'Enregistrer' }, cell(cat, 'a', 'fr'))
    assert_equal({ 'state' => 'needs_review', 'value' => 'Delete' }, cell(cat, 'b', 'fr'), 'an omitted key falls back to English')
  end

  def test_counts_cells_across_locales
    cat = catalog('a' => entry('Save'))
    assert_equal 2, fold(cat, locales: %w[en fr de])
  end

  def test_locales_resolve_independently_in_one_call
    # One fold across three target locales with divergent provenance each — fr via human, de via AI, es reuses
    # an existing machine cell — and each locale's AI call receives only its own fresh keys.
    cat = catalog('a' => entry('Save', locs: { 'es' => unit('needs_review', 'Guardar') }))
    calls = []
    written = fold(
      cat,
      translations: { 'fr' => { 'a' => 'Enregistrer' } },
      locales: %w[en fr de es],
      ai_translator: recording_translator(reply: { 'a' => 'Speichern' }, calls: calls)
    )

    assert_equal 3, written
    assert_equal({ 'state' => 'translated', 'value' => 'Enregistrer' }, cell(cat, 'a', 'fr'))
    assert_equal({ 'state' => 'needs_review', 'value' => 'Speichern' }, cell(cat, 'a', 'de'))
    assert_equal({ 'state' => 'needs_review', 'value' => 'Guardar' }, cell(cat, 'a', 'es'))
    assert_equal(['de'], calls.map { |c| c[:locale] }, 'only de needs the model; fr had a human, es reused')
  end

  def test_summarize_counts_provenance_per_locale
    cat = catalog(
      'a' => entry('Save', locs: { 'fr' => unit('translated', 'Enregistrer') }),   # human
      'b' => entry('Delete', locs: { 'fr' => unit('needs_review', 'Supprimer') }), # machine (differs from English)
      'c' => entry('Post', locs: { 'fr' => unit('needs_review', 'Post') }),        # still English (equals source)
      'd' => entry('Trash')                                                        # no fr cell — not counted
    )
    summary = CatalogStrings.summarize(cat, locales: %w[en fr])

    refute_includes summary.keys, 'en', 'the source locale is not summarized'
    assert_equal({ human: 1, machine: 1, english: 1, samples: [{ key: 'b', english: 'Delete', translation: 'Supprimer' }] }, summary['fr'])
  end

  def test_summarize_caps_machine_samples_at_the_limit
    strings = (1..8).to_h { |i| ["k#{i}", entry("E#{i}", locs: { 'fr' => unit('needs_review', "T#{i}") })] }
    summary = CatalogStrings.summarize(catalog(strings), locales: %w[en fr], sample_limit: 3)['fr']

    assert_equal 8, summary[:machine]
    assert_equal 3, summary[:samples].size, 'samples are capped at sample_limit'
    assert_equal(%w[k1 k2 k3], summary[:samples].map { |ex| ex[:key] })
  end

  def test_summarize_uses_the_key_as_english_for_key_as_source_entries
    cat = catalog('%1$@ on %2$@' => { 'localizations' => { 'fr' => unit('needs_review', '%1$@ on %2$@') } })
    # value equals the key (its English source), so it counts as still-English, not machine.
    assert_equal({ human: 0, machine: 0, english: 1, samples: [] }, CatalogStrings.summarize(cat, locales: %w[en fr])['fr'])
  end

  def test_summary_lines_formats_a_headline_and_indented_samples
    summary = { 'fr' => { human: 3, machine: 1, english: 1, samples: [{ key: 'a', english: 'Save', translation: 'Enregistrer' }] } }
    lines = CatalogStrings.summary_lines(summary)

    assert_equal '  fr: 5 entries — 3 human, 1 machine, 1 still English', lines[0]
    assert_equal '      a: "Save" → "Enregistrer"', lines[1]
  end

  def test_summary_lines_covers_every_locale
    summary = {
      'fr' => { human: 1, machine: 0, english: 0, samples: [] },
      'de' => { human: 0, machine: 1, english: 0, samples: [] }
    }
    assert_equal(
      ['  fr: 1 entries — 1 human, 0 machine, 0 still English', '  de: 1 entries — 0 human, 1 machine, 0 still English'],
      CatalogStrings.summary_lines(summary)
    )
  end

  def test_select_locales_blank_spec_returns_the_whole_map
    map = { 'fr' => 'fr', 'de' => 'de' }
    assert_equal({ selected: map, unknown: [] }, CatalogStrings.select_locales('  ', map))
  end

  def test_select_locales_filters_to_named_and_reports_unknown
    result = CatalogStrings.select_locales('pt-BR,dee', { 'fr' => 'fr', 'de' => 'de', 'pt' => 'pt-BR' })

    assert_equal({ 'pt' => 'pt-BR' }, result[:selected])
    assert_equal ['dee'], result[:unknown], 'a code matching no ship locale is reported, not silently dropped'
  end

  def test_select_locales_reports_empty_when_nothing_matches
    result = CatalogStrings.select_locales('zz', { 'fr' => 'fr' })

    assert_empty result[:selected]
    assert_equal ['zz'], result[:unknown]
  end

  # lproj codes are mixed-case (pt-BR, zh-Hans); a spec typed in any case must resolve, not be dropped as unknown.
  def test_select_locales_matches_lproj_codes_case_insensitively
    result = CatalogStrings.select_locales('pt-br,ZH-HANS', { 'pt' => 'pt-BR', 'zh-cn' => 'zh-Hans', 'fr' => 'fr' })

    assert_equal({ 'pt' => 'pt-BR', 'zh-cn' => 'zh-Hans' }, result[:selected], 'a lowercased/upper spec still resolves to the canonical lproj')
    assert_empty result[:unknown]
  end
end
