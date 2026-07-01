# frozen_string_literal: true

# Pure-Ruby unit suite for AITranslator. Run directly: `ruby fastlane/lanes/ai_translator_test.rb`.
# Uses a canned-reply lambda for `complete:`, so it exercises all of the prompt-building / validation logic
# without the `anthropic` gem or the network.
require 'minitest/autorun'
require_relative 'ai_translator'

# Exercises prompt-building and the validator gate via a canned-reply `complete:` lambda (no gem / network).
class AITranslatorTest < Minitest::Test # rubocop:disable Metrics/ClassLength -- exhaustive scenario coverage
  # Builds a translator whose model "reply" is fixed, optionally recording the prompts it was called with.
  def translator(reply:, prompts: nil)
    complete = lambda do |system:, user:, schema: nil|
      prompts&.replace({ system: system, user: user, schema: schema })
      reply
    end
    AITranslator.new(complete: complete)
  end

  def test_returns_cleaned_translation
    t = translator(reply: %("Réglages"\n)) # wrapped in quotes + trailing newline
    assert_equal 'Réglages', t.translate(source: 'Settings', locale: 'fr')
  end

  def test_accepts_a_reply_that_preserves_placeholders
    t = translator(reply: '%2$@ wurde von %1$@ eingeladen')
    assert_equal '%2$@ wurde von %1$@ eingeladen',
                 t.translate(source: '%1$@ invited %2$@', locale: 'de')
  end

  def test_rejects_a_reply_that_breaks_placeholders
    t = translator(reply: '%1$d Beiträge') # object → int: must be discarded
    assert_nil t.translate(source: '%1$@ posts', locale: 'de')
  end

  def test_blank_source_makes_no_model_call
    called = false
    complete = lambda do |**|
      called = true
      'x'
    end
    t = AITranslator.new(complete: complete)
    assert_nil t.translate(source: "  \n", locale: 'fr')
    refute called
  end

  def test_blank_reply_returns_nil
    assert_nil translator(reply: "  \n").translate(source: 'Settings', locale: 'fr')
  end

  def test_prompt_carries_language_brands_and_context
    prompts = {}
    t = translator(reply: 'Publier', prompts: prompts)
    t.translate(source: 'Publish', locale: 'fr', context: 'Button to publish a post')

    assert_includes prompts[:system], 'French'
    assert_includes prompts[:system], 'WordPress'
    assert_includes prompts[:user], 'Button to publish a post'
    assert_includes prompts[:user], 'Publish'
  end

  def test_for_plural_adapter_maps_arguments_and_cues_category
    prompts = {}
    t = translator(reply: '%1$d Beiträge pro Woche', prompts: prompts)
    out = t.for_plural(
      id: 'blogging.reminders.weeklyCount|==|plural.other',
      source: '%1$d times a week',
      category: 'other',
      note: 'Number of blogging reminders per week.',
      locale: 'de'
    )

    assert_equal '%1$d Beiträge pro Woche', out
    assert_includes prompts[:user], 'Number of blogging reminders per week.'
    assert_includes prompts[:user], 'other' # the CLDR-category cue reaches the prompt
  end

  def test_translate_plural_returns_all_requested_forms
    reply = '{"one":"%1$ld słowo","few":"%1$ld słowa","many":"%1$ld słów","other":"%1$ld słowa"}'
    out = translator(reply: reply).translate_plural(
      english_forms: { 'one' => '%1$ld word', 'other' => '%1$ld words' },
      categories: %w[one few many other], locale: 'pl', note: 'Number of words.'
    )
    assert_equal(
      { 'one' => '%1$ld słowo', 'few' => '%1$ld słowa', 'many' => '%1$ld słów', 'other' => '%1$ld słowa' }, out
    )
  end

  def test_translate_plural_drops_a_form_that_breaks_placeholders
    # 'few' switched %1$ld -> %1$d (length change) — drop it; the rest survive.
    reply = '{"one":"%1$ld słowo","few":"%1$d słowa","other":"%1$ld słowa"}'
    out = translator(reply: reply).translate_plural(
      english_forms: { 'one' => '%1$ld word', 'other' => '%1$ld words' },
      categories: %w[one few other], locale: 'pl'
    )
    assert_equal %w[one other], out.keys.sort
    refute out.key?('few')
  end

  def test_translate_plural_excludes_anchors_and_passes_them_as_context
    prompts = {}
    reply = '{"few":"%1$ld słowa","many":"%1$ld słów","other":"%1$ld słowa"}'
    out = translator(reply: reply, prompts: prompts).translate_plural(
      english_forms: { 'one' => '%1$ld word', 'other' => '%1$ld words' },
      categories: %w[one few many other], locale: 'pl', anchors: { 'one' => '%1$ld słowo' }
    )
    refute out.key?('one') # human-anchored — not produced
    assert_equal %w[few many other], out.keys.sort
    assert_includes prompts[:user], '%1$ld słowo' # anchor shown to the model as fixed context
  end

  def test_translate_plural_falls_back_to_empty_on_bad_json
    out = translator(reply: 'sorry — here are your forms!').translate_plural(
      english_forms: { 'one' => '%1$ld word', 'other' => '%1$ld words' },
      categories: %w[one other], locale: 'pl'
    )
    assert_empty out
  end

  def test_translate_plural_tolerates_json_code_fences
    reply = "```json\n{\"one\":\"%1$ld słowo\",\"other\":\"%1$ld słowa\"}\n```"
    out = translator(reply: reply).translate_plural(
      english_forms: { 'one' => '%1$ld word', 'other' => '%1$ld words' },
      categories: %w[one other], locale: 'pl'
    )
    assert_equal({ 'one' => '%1$ld słowo', 'other' => '%1$ld słowa' }, out)
  end

  def test_translate_plural_validates_fallback_category_against_other
    # 'many' has no English form of its own → validated against the English 'other' (%1$ld words).
    out = translator(reply: '{"many":"%1$ld słów"}').translate_plural(
      english_forms: { 'one' => '%1$ld word', 'other' => '%1$ld words' },
      categories: %w[many], locale: 'pl'
    )
    assert_equal({ 'many' => '%1$ld słów' }, out)
  end

  def test_translate_all_maps_keys_and_validates
    reply = '{"1":"Réglages","2":"%1$@ articles"}'
    out = translator(reply: reply).translate_all(
      [{ key: 'settings.title', source: 'Settings', comment: 'Screen title' },
       { key: 'posts.count', source: '%1$@ posts', comment: 'Count' }],
      locale: 'fr'
    )
    assert_equal({ 'settings.title' => 'Réglages', 'posts.count' => '%1$@ articles' }, out)
  end

  def test_translate_all_drops_a_placeholder_breaker
    reply = '{"1":"Réglages","2":"%1$d articles"}' # item 2 changed %1$@ -> %1$d
    out = translator(reply: reply).translate_all(
      [{ key: 'settings.title', source: 'Settings' }, { key: 'posts.count', source: '%1$@ posts' }],
      locale: 'fr'
    )
    assert_equal({ 'settings.title' => 'Réglages' }, out)
    refute out.key?('posts.count')
  end

  def test_translate_all_skips_blank_sources
    out = translator(reply: '{"1":"Réglages"}').translate_all(
      [{ key: 'settings.title', source: 'Settings' }, { key: 'blank', source: '   ' }],
      locale: 'fr'
    )
    assert_equal({ 'settings.title' => 'Réglages' }, out)
  end

  def test_translate_all_chunks_and_merges
    calls = 0
    complete = lambda do |**|
      calls += 1
      '{"1":"x","2":"y"}'
    end
    out = AITranslator.new(complete: complete).translate_all(
      [{ key: 'a', source: 'One' }, { key: 'b', source: 'Two' }, { key: 'c', source: 'Three' }],
      locale: 'fr', batch_size: 2
    )
    assert_equal 2, calls # 3 items / batch 2 = 2 requests
    assert_equal({ 'a' => 'x', 'b' => 'y', 'c' => 'x' }, out)
  end

  def test_translate_all_bad_json_batch_falls_back
    out = translator(reply: 'not json at all').translate_all([{ key: 'a', source: 'One' }], locale: 'fr')
    assert_empty out
  end

  def test_translate_all_empty_input_makes_no_call
    called = false
    complete = lambda do |**|
      called = true
      '{}'
    end
    assert_empty AITranslator.new(complete: complete).translate_all([], locale: 'fr')
    refute called
  end

  def test_translate_all_prompt_carries_key_context_and_language
    prompts = {}
    translator(reply: '{"1":"Publier"}', prompts: prompts).translate_all(
      [{ key: 'editor.publish', source: 'Publish', comment: 'Publish button' }], locale: 'fr'
    )
    assert_includes prompts[:system], 'French'
    assert_includes prompts[:user], 'editor.publish'
    assert_includes prompts[:user], 'Publish button'
    assert_includes prompts[:user], 'Publish'
  end

  def test_translate_plural_passes_a_schema_of_its_categories
    prompts = {}
    translator(reply: '{"one":"%1$ld słowo","other":"%1$ld słowa"}', prompts: prompts).translate_plural(
      english_forms: { 'one' => '%1$ld word', 'other' => '%1$ld words' }, categories: %w[one other], locale: 'pl'
    )
    assert_equal %w[one other], prompts[:schema]['required'].sort
    assert_equal false, prompts[:schema]['additionalProperties']
  end

  def test_translate_all_passes_a_numbered_schema
    prompts = {}
    translator(reply: '{"1":"a","2":"b"}', prompts: prompts).translate_all(
      [{ key: 'a', source: 'One' }, { key: 'b', source: 'Two' }], locale: 'fr'
    )
    assert_equal %w[1 2], prompts[:schema]['required'].sort
  end

  def test_single_translate_passes_no_schema
    prompts = {}
    translator(reply: 'Publier', prompts: prompts).translate(source: 'Publish', locale: 'fr')
    assert_nil prompts[:schema]
  end

  def test_glossary_terms_and_register_reach_the_prompt
    prompts = {}
    glossary = Glossary.new(terms: { 'fr' => { 'post' => 'article' } }, register: { 'fr' => 'Use formal vous.' })
    complete = lambda do |system:, user:, schema: nil|
      prompts.replace({ system: system, user: user, schema: schema })
      'Publier'
    end
    AITranslator.new(complete: complete, glossary: glossary).translate(source: 'Publish', locale: 'fr')
    assert_includes prompts[:system], 'post -> article'
    assert_includes prompts[:system], 'Register: Use formal vous.'
  end

  def test_prepare_batch_chunks_each_locale_into_jobs
    prep = translator(reply: '{}').prepare_batch(
      { 'fr' => [{ key: 'a', source: 'One' }, { key: 'b', source: 'Two' }, { key: 'c', source: 'Three' }],
        'de' => [{ key: 'a', source: 'One' }] },
      batch_size: 2
    )
    assert_equal(%w[fr_0 fr_1 de_0], prep[:jobs].map { |job| job[:custom_id] })
    assert_equal %w[1 2], prep[:jobs].first[:schema]['required'].sort
  end

  def test_prepare_batch_manifest_maps_custom_id_to_locale_and_strings
    prep = translator(reply: '{}').prepare_batch(
      { 'fr' => [{ key: 'a', source: 'One' }, { key: 'b', source: 'Two' }] }, batch_size: 25
    )
    assert_equal 'fr', prep[:manifest]['fr_0'][:locale]
    assert_equal(%w[a b], prep[:manifest]['fr_0'][:numbered].values.map { |string| string[:key] })
  end

  def test_prepare_batch_custom_ids_match_the_api_pattern
    # The Batch API requires custom_id =~ ^[a-zA-Z0-9_-]{1,64}$ — hyphenated locales like pt-BR must still pass.
    prep = translator(reply: '{}').prepare_batch({ 'pt-BR' => [{ key: 'a', source: 'One' }] }, batch_size: 25)
    prep[:jobs].each { |job| assert_match(/\A[a-zA-Z0-9_-]{1,64}\z/, job[:custom_id]) }
  end

  def test_collect_batch_validates_and_groups_by_locale
    t = translator(reply: '{}')
    prep = t.prepare_batch(
      { 'fr' => [{ key: 'settings', source: 'Settings' }, { key: 'count', source: '%1$@ items' }] }, batch_size: 25
    )
    texts = { 'fr_0' => '{"1":"Réglages","2":"%1$@ éléments"}' }
    assert_equal({ 'fr' => { 'settings' => 'Réglages', 'count' => '%1$@ éléments' } },
                 t.collect_batch(texts, prep[:manifest]))
  end

  def test_collect_batch_drops_invalid_and_missing
    t = translator(reply: '{}')
    prep = t.prepare_batch(
      { 'fr' => [{ key: 'settings', source: 'Settings' }, { key: 'count', source: '%1$@ items' }] }, batch_size: 25
    )
    texts = { 'fr_0' => '{"1":"Réglages","2":"%1$d éléments"}' } # item 2 breaks the placeholder
    assert_equal({ 'fr' => { 'settings' => 'Réglages' } }, t.collect_batch(texts, prep[:manifest]))
  end

  def test_collect_batch_handles_a_missing_batch_reply
    t = translator(reply: '{}')
    prep = t.prepare_batch({ 'fr' => [{ key: 'a', source: 'One' }] }, batch_size: 25)
    assert_equal({ 'fr' => {} }, t.collect_batch({}, prep[:manifest]))
  end

  # When a translation's value is itself wrapped in quotation marks, those quotes are part of the content and
  # must survive — only the model's cosmetic wrapping around a raw reply should be stripped.
  def test_translate_plural_preserves_a_quoted_value
    reply = '{"other":"\"Reader\""}'
    out = translator(reply: reply).translate_plural(
      english_forms: { 'other' => '"Reader"' },
      categories: %w[other], locale: 'fr'
    )
    assert_equal({ 'other' => '"Reader"' }, out)
  end

  def test_translate_all_preserves_a_quoted_value
    reply = '{"1":"\"Reader\""}'
    out = translator(reply: reply).translate_all(
      [{ key: 'sample.quoted', source: '"Reader"' }], locale: 'fr'
    )
    assert_equal({ 'sample.quoted' => '"Reader"' }, out)
  end

  # The same holds for the curly/smart quotes clean() also strips: a JSON-decoded value wrapped in “ ” keeps them.
  def test_translate_all_preserves_a_curly_quoted_value
    reply = '{"1":"“Reader”"}'
    out = translator(reply: reply).translate_all(
      [{ key: 'sample.curly', source: '“Reader”' }], locale: 'fr'
    )
    assert_equal({ 'sample.curly' => '“Reader”' }, out)
  end

  # The async Batch path shares select_valid_batch with translate_all, so it must preserve a quoted value too.
  def test_collect_batch_preserves_a_quoted_value
    t = translator(reply: '{}')
    prep = t.prepare_batch({ 'fr' => [{ key: 'sample.quoted', source: '"Reader"' }] }, batch_size: 25)
    texts = { 'fr_0' => '{"1":"\"Reader\""}' }
    assert_equal({ 'fr' => { 'sample.quoted' => '"Reader"' } }, t.collect_batch(texts, prep[:manifest]))
  end
end
