# frozen_string_literal: true

# Pure-Ruby unit suite for PluralStrings.fold_translations! — the reverse fold that folds downloaded plural
# translations back into the String Catalog with the `human ?? AI ?? English` floor. Run directly:
# `ruby fastlane/lanes/plural_strings_helper_test.rb`. No bundle / network (the AI tier is a stub lambda).
require 'minitest/autorun'
require 'stringio'
require_relative 'plural_strings_helper'

# Exercises provenance (human => translated; AI / English fallback => needs_review) and the form-set contract:
# the AI tier is called ONCE per (key, locale) with the whole set of needed categories and the human forms as
# anchors — never per cell.
class PluralStringsFoldTest < Minitest::Test # rubocop:disable Metrics/ClassLength -- exhaustive scenario coverage
  KEY = 'posts.count'
  INFIX = PluralStrings::INFIX

  def unit(state, value)
    { 'stringUnit' => { 'state' => state, 'value' => value } }
  end

  # A catalog with one English plural (one/other). `extra` adds sibling entries (e.g. a non-plural string).
  def catalog(extra: {})
    {
      'sourceLanguage' => 'en',
      'version' => '1.0',
      'strings' => {
        KEY => {
          'comment' => 'Number of posts.',
          'localizations' => { 'en' => { 'variations' => { 'plural' => {
            'one' => unit('translated', '%lld post'),
            'other' => unit('translated', '%lld posts')
          } } } }
        }
      }.merge(extra)
    }
  end

  # The full stringUnit wrapper a fold wrote for (locale, category) of the plural key under test.
  def cell(cat, catalog:, locale:)
    catalog.dig('strings', KEY, 'localizations', locale, 'variations', 'plural', cat)
  end

  # An AI stub returning `reply`, recording every call's kwargs so the form-set contract can be asserted.
  def recording_translator(reply:, calls:)
    lambda do |english_forms:, categories:, locale:, note:, anchors:|
      calls << { english_forms: english_forms, categories: categories, locale: locale, note: note, anchors: anchors }
      reply
    end
  end

  def fold(cat, categories_by_locale:, translations_by_locale: {}, ai_translator: nil)
    PluralStrings.fold_translations!(cat, categories_by_locale: categories_by_locale, translations_by_locale: translations_by_locale, ai_translator: ai_translator)
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

  # Polish needs four categories but only `one` is human-translated — the setup the form-set contract is about.
  # Folds with the supplied AI reply and returns [catalog, recorded_calls].
  def fold_polish(reply:)
    cat = catalog
    calls = []
    fold(cat,
         categories_by_locale: { 'pl' => %w[one few many other] },
         translations_by_locale: { 'pl' => { "#{KEY}#{INFIX}one" => '%lld wpis' } },
         ai_translator: recording_translator(reply: reply, calls: calls))
    [cat, calls]
  end

  POLISH_AI = { 'few' => '%lld wpisy', 'many' => '%lld wpisów', 'other' => '%lld wpisu' }.freeze

  def test_human_translation_wins_and_is_marked_translated
    cat = catalog
    written = fold(cat, categories_by_locale: { 'fr' => %w[one other] }, translations_by_locale: {
                     'fr' => { "#{KEY}#{INFIX}one" => '%lld article', "#{KEY}#{INFIX}other" => '%lld articles' }
                   })

    assert_equal 1, written
    assert_equal unit('translated', '%lld article'), cell('one', catalog: cat, locale: 'fr')
    assert_equal unit('translated', '%lld articles'), cell('other', catalog: cat, locale: 'fr')
  end

  # A human form that drops/retypes a specifier would crash at runtime. It must be REJECTED (same gate the AI
  # forms pass) and surfaced, then fall through to the model — never shipping as `translated` and never anchoring
  # the request. A valid sibling human form in the same set still ships.
  def test_placeholder_broken_human_form_is_rejected_and_surfaced_not_shipped
    cat = catalog
    calls = []
    ai = recording_translator(reply: { 'one' => '%lld article' }, calls: calls)
    warnings = capture_stderr do
      fold(cat, categories_by_locale: { 'fr' => %w[one other] },
                translations_by_locale: { 'fr' => { "#{KEY}#{INFIX}one" => 'article', # %lld dropped -> rejected
                                                    "#{KEY}#{INFIX}other" => '%lld articles' } }, # valid human
                ai_translator: ai)
    end

    assert_equal unit('needs_review', '%lld article'), cell('one', catalog: cat, locale: 'fr'), 'a broken human form falls through to AI'
    assert_equal unit('translated', '%lld articles'), cell('other', catalog: cat, locale: 'fr'), 'the valid human form still ships'
    assert_equal({ 'other' => '%lld articles' }, calls.first[:anchors], 'a rejected human form must not anchor the request')
    assert_match(/rejected fr human translation for "#{KEY}" \(one\)/, warnings)
  end

  def test_english_fallback_when_no_human_and_no_ai
    cat = catalog
    fold(cat, categories_by_locale: { 'fr' => %w[one other] })

    # No human, no AI tier wired: each cell falls through to the English source, flagged for review.
    assert_equal unit('needs_review', '%lld post'), cell('one', catalog: cat, locale: 'fr')
    assert_equal unit('needs_review', '%lld posts'), cell('other', catalog: cat, locale: 'fr')
  end

  def test_ai_fills_missing_cells_and_marks_needs_review
    cat = catalog
    ai = recording_translator(reply: { 'one' => '%lld article', 'other' => '%lld articles' }, calls: [])
    fold(cat, categories_by_locale: { 'fr' => %w[one other] }, ai_translator: ai)

    assert_equal unit('needs_review', '%lld article'), cell('one', catalog: cat, locale: 'fr')
    assert_equal unit('needs_review', '%lld articles'), cell('other', catalog: cat, locale: 'fr')
  end

  def test_formset_call_carries_english_forms_anchors_and_note
    _cat, calls = fold_polish(reply: POLISH_AI)

    assert_equal 1, calls.size, 'expected a single form-set call, not one per category'
    call = calls.first
    assert_equal %w[one few many other], call[:categories]
    assert_equal 'pl', call[:locale]
    assert_equal 'Number of posts.', call[:note]
    assert_equal({ 'one' => '%lld wpis' }, call[:anchors])
    # few/many/other have no English form of their own, so they fall back to the English `other` value.
    assert_equal({ 'one' => '%lld post', 'few' => '%lld posts', 'many' => '%lld posts', 'other' => '%lld posts' }, call[:english_forms])
  end

  def test_formset_result_merges_human_and_ai_by_provenance
    cat, = fold_polish(reply: POLISH_AI)

    assert_equal unit('translated', '%lld wpis'), cell('one', catalog: cat, locale: 'pl') # human
    assert_equal unit('needs_review', '%lld wpisy'), cell('few', catalog: cat, locale: 'pl') # AI
    assert_equal unit('needs_review', '%lld wpisów'), cell('many', catalog: cat, locale: 'pl')
    assert_equal unit('needs_review', '%lld wpisu'), cell('other', catalog: cat, locale: 'pl')
  end

  def test_ai_omitted_category_falls_back_to_english
    cat = catalog
    ai = recording_translator(reply: { 'one' => '%lld Beitrag' }, calls: []) # 'other' omitted
    fold(cat, categories_by_locale: { 'de' => %w[one other] }, ai_translator: ai)

    assert_equal unit('needs_review', '%lld Beitrag'), cell('one', catalog: cat, locale: 'de')
    assert_equal unit('needs_review', '%lld posts'), cell('other', catalog: cat, locale: 'de') # English fallback
  end

  def test_ai_nil_return_falls_back_to_english
    cat = catalog
    fold(cat, categories_by_locale: { 'de' => %w[one other] }, ai_translator: ->(**) {}) # declines entirely (nil)

    assert_equal unit('needs_review', '%lld post'), cell('one', catalog: cat, locale: 'de')
    assert_equal unit('needs_review', '%lld posts'), cell('other', catalog: cat, locale: 'de')
  end

  def test_source_locale_is_not_folded
    cat = catalog
    original_en = cat.dig('strings', KEY, 'localizations', 'en')
    written = fold(cat, categories_by_locale: { 'en' => %w[one other], 'fr' => %w[one other] })

    assert_equal 1, written, 'the source locale must be excluded from the fold'
    assert_same original_en, cat.dig('strings', KEY, 'localizations', 'en'), 'source localization left untouched'
    refute_nil cell('one', catalog: cat, locale: 'fr')
  end

  def test_non_plural_entries_are_skipped
    extra = { 'app.title' => { 'localizations' => { 'en' => unit('translated', 'WordPress') } } }
    cat = catalog(extra: extra)
    written = fold(cat, categories_by_locale: { 'fr' => %w[one other] })

    assert_equal 1, written, 'only the plural entry is counted'
    # The non-plural entry is left exactly as it was — no `fr` localization invented for it.
    assert_equal({ 'en' => unit('translated', 'WordPress') }, cat.dig('strings', 'app.title', 'localizations'))
  end

  def test_counts_variations_across_locales
    cat = catalog
    written = fold(cat, categories_by_locale: { 'fr' => %w[one other], 'de' => %w[one other] })

    assert_equal 2, written
  end

  # Re-running the fold with unchanged input must not re-call the model: the prior AI cells are carried over as
  # anchors, so nothing is left to translate and the staged text is stable (no re-spend, no churn).
  def test_rerun_preserves_ai_cells_and_skips_the_model
    cat, first_calls = fold_polish(reply: POLISH_AI)
    assert_equal 1, first_calls.size

    second_calls = []
    # A translator that would return DIFFERENT text if called — proving the re-run never touches it.
    fold(cat,
         categories_by_locale: { 'pl' => %w[one few many other] },
         translations_by_locale: { 'pl' => { "#{KEY}#{INFIX}one" => '%lld wpis' } },
         ai_translator: recording_translator(reply: { 'few' => 'DRIFT', 'many' => 'DRIFT', 'other' => 'DRIFT' }, calls: second_calls))

    assert_empty second_calls, 'a re-run must not re-call the model for cells it already filled'
    # The staged cells are unchanged: human `one`, and the first run's AI `few/many/other` (never the DRIFT text).
    expected = { 'variations' => { 'plural' => {
      'one' => unit('translated', '%lld wpis'),
      'few' => unit('needs_review', '%lld wpisy'),
      'many' => unit('needs_review', '%lld wpisów'),
      'other' => unit('needs_review', '%lld wpisu')
    } } }
    assert_equal expected, cat.dig('strings', KEY, 'localizations', 'pl')
  end

  # A cell that fell back to English (the AI declined) is machine output only in name — it must be retried on the
  # next run, not preserved, so a transient outage doesn't freeze English into the catalog.
  def test_english_fallback_cells_are_retried_on_the_next_run
    cat = catalog
    fold(cat, # first run: AI declines entirely, so few/many/other fall back to English
         categories_by_locale: { 'pl' => %w[one few many other] },
         translations_by_locale: { 'pl' => { "#{KEY}#{INFIX}one" => '%lld wpis' } },
         ai_translator: ->(**) {})
    assert_equal unit('needs_review', '%lld posts'), cell('few', catalog: cat, locale: 'pl')

    calls = []
    fold(cat, # second run: AI recovers — the English-fallback cells must be re-offered to it
         categories_by_locale: { 'pl' => %w[one few many other] },
         translations_by_locale: { 'pl' => { "#{KEY}#{INFIX}one" => '%lld wpis' } },
         ai_translator: recording_translator(reply: POLISH_AI, calls: calls))

    assert_equal 1, calls.size, 'English-fallback cells must be retried when the AI tier recovers'
    assert_equal({ 'one' => '%lld wpis' }, calls.first[:anchors], 'only the human form anchors; English-fallback cells are not kept')
    assert_equal unit('needs_review', '%lld wpisy'), cell('few', catalog: cat, locale: 'pl')
  end

  # When a human translation arrives for a category the AI filled last run, it supersedes the machine cell; with
  # every category now human- or kept-AI-covered, no model call is made.
  def test_human_translation_supersedes_a_prior_ai_cell
    cat, = fold_polish(reply: POLISH_AI)
    assert_equal unit('needs_review', '%lld wpisy'), cell('few', catalog: cat, locale: 'pl')

    calls = []
    fold(cat,
         categories_by_locale: { 'pl' => %w[one few many other] },
         translations_by_locale: { 'pl' => { "#{KEY}#{INFIX}one" => '%lld wpis', "#{KEY}#{INFIX}few" => '%lld wpisy!' } },
         ai_translator: recording_translator(reply: {}, calls: calls))

    assert_equal unit('translated', '%lld wpisy!'), cell('few', catalog: cat, locale: 'pl')
    assert_empty calls, 'human + kept-AI cover every category, so no model call'
  end

  # A source form left explicitly blank (only `other` carries text) must fall back to the English `other`, never
  # ship a blank plural cell.
  def test_blank_source_form_falls_back_to_english_not_empty
    cat = {
      'sourceLanguage' => 'en',
      'strings' => { KEY => { 'localizations' => { 'en' => { 'variations' => { 'plural' => {
        'one' => unit('translated', ''),
        'other' => unit('translated', '%lld posts')
      } } } } } }
    }
    fold(cat, categories_by_locale: { 'de' => %w[one other] })

    assert_equal unit('needs_review', '%lld posts'), cell('one', catalog: cat, locale: 'de')
    assert_equal unit('needs_review', '%lld posts'), cell('other', catalog: cat, locale: 'de')
  end

  # A whitespace-only GlotPress value is not a real translation: it must not ship as `translated`, must not anchor
  # the AI request, and the category falls through to AI / English instead.
  def test_whitespace_only_human_value_is_treated_as_untranslated
    cat = catalog
    calls = []
    fold(cat,
         categories_by_locale: { 'pl' => %w[one other] },
         translations_by_locale: { 'pl' => { "#{KEY}#{INFIX}one" => '   ', "#{KEY}#{INFIX}other" => '%lld wpisów' } },
         ai_translator: recording_translator(reply: { 'one' => '%lld wpis' }, calls: calls))

    assert_equal({ 'other' => '%lld wpisów' }, calls.first[:anchors], 'a blank human value must not anchor the request')
    assert_equal unit('needs_review', '%lld wpis'), cell('one', catalog: cat, locale: 'pl')
    assert_equal unit('translated', '%lld wpisów'), cell('other', catalog: cat, locale: 'pl')
  end
end
