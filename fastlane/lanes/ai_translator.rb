# frozen_string_literal: true

require 'json'
require_relative 'anthropic_batch'
require_relative 'translation_glossary'
require_relative 'translation_validator'

# AI translation tier for the localization pipeline — the service behind the `human ?? AI ?? English` floor.
#
# `localization_plurals.rb` currently stubs `ai_translate_plural(...)` to return nil; this is what replaces
# it. Given an English source string, a target locale, and the developer context, it asks Claude for a
# translation, then runs the result through `TranslationValidator` before returning it. Anything that fails
# the format-specifier gate (or comes back empty / refused) returns nil — the documented "no machine
# translation" signal the fold treats as English-fallback (flagged needs_review). It never returns a
# placeholder-broken string.
#
# The model call is INJECTED as a `complete` callable, not hard-wired, so the prompt-building and validation
# logic stays pure and unit-testable without the SDK or the network. `AITranslator.with_anthropic` builds the
# live, Claude-backed instance; the unit tests build one around a canned-reply lambda.
class AITranslator # rubocop:disable Metrics/ClassLength -- mostly static localization config (33-locale name map + prompt templates)
  DEFAULT_MODEL = 'claude-opus-4-8'

  # lproj code → human language name for the prompt. Covers the current ship locales; an unmapped code falls
  # back to itself (the model still does something reasonable, but add the name here for best results).
  LANGUAGE_NAMES = {
    'ar' => 'Arabic', 'bg' => 'Bulgarian', 'cs' => 'Czech', 'cy' => 'Welsh', 'da' => 'Danish',
    'de' => 'German', 'en-AU' => 'English (Australia)', 'en-CA' => 'English (Canada)',
    'en-GB' => 'English (United Kingdom)', 'es' => 'Spanish', 'fr' => 'French', 'he' => 'Hebrew',
    'hr' => 'Croatian', 'hu' => 'Hungarian', 'id' => 'Indonesian', 'is' => 'Icelandic', 'it' => 'Italian',
    'ja' => 'Japanese', 'ko' => 'Korean', 'nb' => 'Norwegian Bokmål', 'nl' => 'Dutch', 'pl' => 'Polish',
    'pt' => 'Portuguese', 'pt-BR' => 'Portuguese (Brazil)', 'ro' => 'Romanian', 'ru' => 'Russian',
    'sk' => 'Slovak', 'sq' => 'Albanian', 'sv' => 'Swedish', 'th' => 'Thai', 'tr' => 'Turkish',
    'zh-Hans' => 'Chinese (Simplified)', 'zh-Hant' => 'Chinese (Traditional)'
  }.freeze

  # `{{language}}` / `{{brands}}` are substituted by literal gsub (NOT `format`/`%`, which would choke on the
  # literal `%@` / `%1$@` examples below). Shared by the single-string and plural prompts.
  TRANSLATION_RULES = <<~PROMPT
    You are an expert software localizer translating user-facing UI strings for the WordPress and Jetpack iOS apps into {{language}}.

    Rules:
    - Translate into natural, concise {{language}} suitable for a mobile app UI. Screen space is limited, so prefer the shorter faithful phrasing.
    - Keep these names EXACTLY as written, untranslated: {{brands}}.
    - Preserve every format specifier (e.g. %@, %1$@, %d, %lld, %1$d) EXACTLY — same count and type. You may reorder positional specifiers such as %1$@ and %2$d to suit the target grammar, but each must appear exactly once and keep its number.
    - Preserve any HTML tags, markup, and leading/trailing whitespace exactly as in the source.
    - Do not translate URLs, email addresses, file paths, or code.
    - Follow the tone and terminology conventions of the WordPress.org {{language}} translation community, including its formal/informal form-of-address convention.
  PROMPT

  # Output instruction for a single string.
  SINGLE_OUTPUT = 'Output ONLY the translated string — no quotation marks, no explanation, no notes, nothing else.'

  # Output instruction for a plural form-set. The consistency rule is the whole reason to translate the forms
  # together (one request) rather than per category: it stops the model drifting between synonyms across forms
  # (e.g. Polish słowo -> wyrazy -> słów), which a per-cell call structurally cannot prevent.
  PLURAL_OUTPUT = <<~PROMPT
    You are translating the plural forms of ONE UI string. Use a single consistent word and stem across every form — only the grammatical inflection (ending) changes between forms; never switch to a synonym between forms.

    Return ONLY a JSON object mapping each requested CLDR plural category to its translation, e.g. {"one": "...", "other": "..."}. No markdown fences, no commentary — just the JSON object.
  PROMPT

  # Brief, locale-agnostic cue per CLDR category (the model knows the language's actual rules; this just
  # disambiguates which form we're asking for).
  CLDR_CUES = {
    'zero' => 'the zero form',
    'one' => 'singular (n = 1)',
    'two' => 'the dual form (n = 2)',
    'few' => 'the "few" form (e.g. 2-4 in many Slavic languages)',
    'many' => 'the "many" form (e.g. 5+ in many Slavic languages)',
    'other' => 'the general / catch-all form (also used for fractions)'
  }.freeze

  # Default number of strings per batched request. Small enough to keep each JSON reply parseable and bound the
  # blast radius if one reply is malformed (only that batch falls back to English); large enough to amortize the
  # cached system prompt across many strings.
  DEFAULT_BATCH_SIZE = 25

  # Output instruction for a batch of independent strings (keyed by item number, not the long reverse-DNS key,
  # so the model can't garble the mapping).
  BATCH_OUTPUT = <<~PROMPT
    You are translating a batch of independent UI strings. Translate each on its own; the items are unrelated unless a context note says otherwise.

    Return ONLY a JSON object mapping each item's number (as a string) to its translation, e.g. {"1": "...", "2": "..."}. Include every number you are given, and translate nothing else. No markdown fences, no commentary — just the JSON object.
  PROMPT

  # @param complete [#call] callable invoked as `complete.call(system:, user:, schema: nil)` returning the
  #   model's raw text reply. Injected so the translator is testable without the SDK.
  # @param glossary [Glossary] brand do-not-translate list + per-locale terms/register (translation_glossary.rb).
  # @param language_names [Hash{String=>String}] lproj code → language name.
  def initialize(complete:, glossary: Glossary.default, language_names: LANGUAGE_NAMES)
    @complete = complete
    @glossary = glossary
    @language_names = language_names
  end

  # Validated translation of `source` into `locale`, or nil if one can't be produced SAFELY: blank source, a
  # blank/garbled reply, or — critically — a reply that breaks the format-specifier contract.
  #
  # @param source [String] the English source string.
  # @param locale [String] target lproj code (e.g. "fr", "pt-BR", "zh-Hans").
  # @param context [String, nil] developer comment / context for the string (the `comment:` field). Feeding
  #   this is the single biggest quality lever, so pass it whenever available.
  def translate(source:, locale:, context: nil)
    source = source.to_s
    return nil if source.strip.empty?

    candidate = clean(@complete.call(system: system_prompt(locale), user: user_prompt(source, context)).to_s)
    return nil if candidate.empty?
    return nil unless TranslationValidator.placeholders_match?(source, candidate)

    candidate
  end

  # Per-cell adapter matching the legacy `ai_translate_plural(id:, source:, category:, note:, locale:)` stub
  # contract in `localization_plurals.rb`: it translates ONE plural form on its own through single-string
  # `translate`. Each form is an independent request, so it CANNOT keep one consistent word/stem across the
  # forms — it is subject to exactly the lemma drift `PLURAL_OUTPUT` and `translate_plural` describe. This is a
  # per-cell fallback, NOT the way to wire the live tier.
  #
  # The drift-free path is `translate_plural` — the whole form-set in one request. Because it is a
  # per-(key, locale) call, wiring it upgrades the consumer's `ai_translator` seam to take the form-set
  # (`ai_translator.call(english_forms:, categories:, locale:, note:, anchors:)`); it is not a one-line swap here.
  # rubocop:disable Lint/UnusedMethodArgument -- keyword names are the documented call contract
  def for_plural(id:, source:, category:, note:, locale:)
    translate(source: source, locale: locale, context: plural_context(note, category))
  end
  # rubocop:enable Lint/UnusedMethodArgument

  # Translates a whole plural form-set for one key in a SINGLE request, so the model keeps one consistent
  # word/stem across the forms (the fix for per-cell lemma drift). Returns { category => translation } for the
  # requested categories, each placeholder-validated against its English source; forms that fail the gate or
  # are absent from the reply are omitted, so the caller falls back to English (needs_review) for those.
  #
  # @param english_forms [Hash{String=>String}] English plural forms by CLDR category (must include "other";
  #   a requested category with no English form of its own falls back to the "other" English value).
  # @param categories [Array<String>] the CLDR categories to produce (the ones the target locale needs).
  # @param locale [String] target lproj code.
  # @param note [String, nil] developer context / comment for the string.
  # @param anchors [Hash{String=>String}] already-finalized (e.g. human-translated) forms — shown to the model
  #   as fixed context to stay consistent with, and excluded from what it is asked to produce.
  def translate_plural(english_forms:, categories:, locale:, note: nil, anchors: {})
    english_forms = to_string_keys(english_forms)
    anchors = to_string_keys(anchors)
    return {} if english_forms['other'].to_s.strip.empty?

    needed = categories.map(&:to_s) - anchors.keys
    return {} if needed.empty?

    reply = @complete.call(
      system: plural_system_prompt(locale),
      user: plural_user_prompt(english_forms, needed, note, anchors),
      schema: object_schema(needed)
    )
    select_valid_forms(parse_forms(reply), needed, english_forms)
  end

  # Translates many independent strings in batched requests (default DEFAULT_BATCH_SIZE per request), returning
  # { key => translation } for those that pass the placeholder gate. Strings absent from the result (gate
  # failure, blank source, or a malformed batch reply) fall back to human/English at the call site. Pass the
  # strings already sorted by key so each batch naturally groups one feature (reader.*, editor.*) — better
  # terminology consistency within a batch.
  #
  # @param strings [Array<Hash>] each { key:, source:, comment: } (string or symbol keys both accepted).
  # @param locale [String] target lproj code.
  # @param batch_size [Integer] strings per request.
  def translate_all(strings, locale:, batch_size: DEFAULT_BATCH_SIZE)
    items = batchable_items(strings)
    return {} if items.empty?

    items.each_slice(batch_size).with_object({}) do |chunk, out|
      out.merge!(translate_batch(chunk, locale))
    end
  end

  # Builds Message Batch jobs for many strings across many locales (the async / cheaper bulk path). Returns
  # { jobs:, manifest: }: `jobs` ({ custom_id:, system:, user:, schema: }) go to `AnthropicBatch.submit`;
  # `manifest` (custom_id => { locale:, numbered: }) is handed back to `collect_batch` with the batch results.
  # Pure — no model or SDK here; `AnthropicBatch.submit` adds the model when it builds the requests.
  #
  # @param strings_by_locale [Hash{String=>Array<Hash>}] locale => array of { key:, source:, comment: }.
  def prepare_batch(strings_by_locale, batch_size: DEFAULT_BATCH_SIZE)
    jobs = []
    manifest = {}
    strings_by_locale.each do |locale, strings|
      batchable_items(strings).each_slice(batch_size).with_index do |chunk, index|
        numbered = number_chunk(chunk)
        custom_id = "#{locale}_#{index}" # must match ^[a-zA-Z0-9_-]{1,64}$; locale codes have hyphens, not underscores, so this stays unique
        jobs << batch_job(custom_id, locale, numbered)
        manifest[custom_id] = { locale: locale, numbered: numbered }
      end
    end
    { jobs: jobs, manifest: manifest }
  end

  # Validates the batch replies and assembles { locale => { key => translation } }. `texts_by_custom_id` comes
  # from `AnthropicBatch.results`; `manifest` from `prepare_batch`. A custom_id with no reply (errored batch
  # request) or a per-string gate failure simply doesn't appear → the caller falls back to human/English. Pure.
  def collect_batch(texts_by_custom_id, manifest)
    manifest.each_with_object({}) do |(custom_id, entry), result|
      bucket = (result[entry[:locale]] ||= {})
      text = texts_by_custom_id[custom_id]
      next if text.nil?

      bucket.merge!(select_valid_batch(parse_forms(text), entry[:numbered]))
    end
  end

  # Builds a translator backed by the Anthropic Ruby SDK (`gem 'anthropic'`, in the Gemfile) — needs
  # ANTHROPIC_API_KEY in the env. This `complete` lambda is the only part of the file the unit tests don't
  # exercise, by design: everything the tests cover stays on the pure side of the injection boundary.
  def self.with_anthropic(api_key: ENV.fetch('ANTHROPIC_API_KEY', nil), model: DEFAULT_MODEL, **)
    client = AnthropicBatch.client(api_key: api_key)
    complete = lambda do |system:, user:, schema: nil|
      AnthropicBatch.text_of(client.messages.create(**AnthropicBatch.message_params(model: model, system: system, user: user, schema: schema)))
    end
    new(complete: complete, **)
  rescue LoadError
    raise LoadError, "The `anthropic` gem (in the Gemfile) isn't installed — run `bundle install` (or `gem install anthropic`)."
  end

  private

  # Shared rule block (brands, format specifiers) with {{language}}/{{brands}} filled in, plus the glossary's
  # per-locale terms + register note appended when present.
  def render_rules(locale)
    language = @language_names.fetch(locale, locale)
    rules = TRANSLATION_RULES.gsub('{{language}}') { language }.gsub('{{brands}}') { @glossary.do_not_translate.join(', ') }
    guidance = @glossary.guidance(locale)
    guidance.empty? ? rules : "#{rules}\n#{guidance}"
  end

  def system_prompt(locale)
    "#{render_rules(locale)}\n#{SINGLE_OUTPUT}"
  end

  def plural_system_prompt(locale)
    "#{render_rules(locale)}\n#{PLURAL_OUTPUT}"
  end

  def user_prompt(source, context)
    parts = []
    parts << "Context: #{context}" if context && !context.to_s.strip.empty?
    parts << "English source string:\n#{source}"
    parts.join("\n\n")
  end

  def plural_user_prompt(english_forms, needed, note, anchors)
    sections = []
    sections << "Context: #{note}" if note && !note.to_s.strip.empty?
    sections << "English source forms:\n#{format_forms(english_forms)}"
    sections << "Already-finalized forms — match their exact word choice and stem, and do not re-output them:\n#{format_forms(anchors)}" unless anchors.empty?
    catalog = needed.map { |category| "  #{category} - #{CLDR_CUES.fetch(category, category)}" }.join("\n")
    sections << "Translate these CLDR plural categories, returning a JSON object keyed exactly by these category names:\n#{catalog}"
    sections.join("\n\n")
  end

  def format_forms(forms)
    forms.map { |category, value| "  #{category} = #{value}" }.join("\n")
  end

  # Keep only the parsed forms whose placeholders match their English source (the form's own English, or the
  # "other" value for categories English doesn't distinguish). Failed/empty forms are dropped → English fallback.
  def select_valid_forms(parsed, needed, english_forms)
    other = english_forms['other']
    needed.each_with_object({}) do |category, out|
      candidate = parsed[category].to_s.strip # already JSON-decoded — trim only; clean() would strip a value's own quotes
      next if candidate.empty?

      source = english_forms[category] || other
      out[category] = candidate if TranslationValidator.placeholders_match?(source, candidate)
    end
  end

  # JSON Schema for a flat object whose values are all required strings — passed as `output_config.format` to
  # make the model emit exactly this shape (structured outputs). additionalProperties must be false; that's the
  # only form structured outputs support, and it also stops the model inventing extra keys.
  def object_schema(keys)
    {
      'type' => 'object',
      'properties' => keys.to_h { |key| [key, { 'type' => 'string' }] },
      'required' => keys,
      'additionalProperties' => false
    }
  end

  # Parse the model's JSON reply into { key => value }; tolerate ```json fences; {} on any parse failure
  # (every entry then falls back to English — safe, though structured outputs make a failure very unlikely).
  def parse_forms(reply)
    text = reply.to_s.strip.sub(/\A```(?:json)?\s*/i, '').sub(/```\s*\z/, '').strip
    data = JSON.parse(text)
    data.is_a?(Hash) ? data : {}
  rescue JSON::ParserError
    {}
  end

  def to_string_keys(hash)
    (hash || {}).each_with_object({}) { |(key, value), acc| acc[key.to_s] = value }
  end

  # One batched request: number the chunk, ask for a JSON {number => translation}, keep the validated ones.
  def translate_batch(chunk, locale)
    numbered = number_chunk(chunk)
    reply = @complete.call(
      system: batch_system_prompt(locale),
      user: batch_user_prompt(numbered),
      schema: object_schema(numbered.keys.map(&:to_s))
    )
    select_valid_batch(parse_forms(reply), numbered)
  end

  # Map each numbered item to its validated translation by key; drop empty/placeholder-breaking ones.
  def select_valid_batch(parsed, numbered)
    numbered.each_with_object({}) do |(index, string), out|
      candidate = parsed[index.to_s].to_s.strip # already JSON-decoded — trim only; clean() would strip a value's own quotes
      next if candidate.empty?

      out[string[:key]] = candidate if TranslationValidator.placeholders_match?(string[:source], candidate)
    end
  end

  def batch_system_prompt(locale)
    "#{render_rules(locale)}\n#{BATCH_OUTPUT}"
  end

  def batch_user_prompt(numbered)
    items = numbered.map { |index, string| batch_item_line(index, string) }
    "Translate each numbered UI string below into the target language.\n\n#{items.join("\n")}"
  end

  # One prompt line per string: number, the reverse-DNS key (UI-role context), the English, and the dev note.
  def batch_item_line(index, string)
    line = "[#{index}] "
    line << "(#{string[:key]}) " unless string[:key].to_s.empty?
    line << string[:source].to_s
    line << " — #{string[:comment]}" unless string[:comment].to_s.strip.empty?
    line
  end

  def normalize_string(string)
    { key: field(string, :key), source: field(string, :source), comment: field(string, :comment) }
  end

  def field(hash, name)
    hash[name] || hash[name.to_s]
  end

  # Normalize to { key:, source:, comment: } hashes and drop entries with a blank source (nothing to translate).
  def batchable_items(strings)
    strings.map { |string| normalize_string(string) }.reject { |string| string[:source].to_s.strip.empty? }
  end

  # Number a chunk 1..N → { 1 => string, … } (the index the model maps its JSON reply by).
  def number_chunk(chunk)
    chunk.each_with_index.to_h { |string, index| [index + 1, string] }
  end

  def batch_job(custom_id, locale, numbered)
    {
      custom_id: custom_id,
      system: batch_system_prompt(locale),
      user: batch_user_prompt(numbered),
      schema: object_schema(numbered.keys.map(&:to_s))
    }
  end

  # Strip the cosmetic wrapper a model sometimes adds to a RAW single-string reply — wrapping quotes or a
  # trailing newline, despite the "only the translation" instruction. Only ever run this on a raw reply, never
  # on a JSON-decoded value: JSON.parse has already removed the structural quotes, so any quotes left there are
  # part of the content (a value like "Reader" must keep them). Anything more substantial (a prose explanation
  # that slipped through) almost always breaks the placeholder gate and is discarded there.
  def clean(text)
    stripped = text.strip
    if stripped.length >= 2 &&
       ((stripped.start_with?('"') && stripped.end_with?('"')) ||
        (stripped.start_with?('“') && stripped.end_with?('”')))
      stripped = stripped[1...-1].strip
    end
    stripped
  end

  # The dev note plus an explicit CLDR-category cue, so the model produces the correct grammatical plural
  # form (e.g. the Polish `few` form) rather than guessing from the English source alone.
  def plural_context(note, category)
    [note, "Plural category: #{category}. Render the grammatically correct plural form for this category."]
      .compact.reject(&:empty?).join(' ')
  end
end

# Tiny CLI to eyeball quality against the real model (needs the `anthropic` gem + ANTHROPIC_API_KEY):
#   ruby fastlane/lanes/ai_translator.rb fr "You have %1$d new posts" "Notification text. %1$d is the count."
if __FILE__ == $PROGRAM_NAME
  locale, source, context = ARGV
  abort("usage: ruby #{File.basename(__FILE__)} <locale> \"<english>\" [\"<context>\"]") unless locale && source

  result = AITranslator.with_anthropic.translate(source: source, locale: locale, context: context)
  puts result.nil? ? '(no safe translation — placeholder check failed or empty reply)' : result
end
