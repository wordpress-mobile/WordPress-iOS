# frozen_string_literal: true

require 'json'

# Translates UI strings with Claude. Used by the daily translation sync to
# backfill locales that GlotPress hasn't fully translated yet, so the app never
# ships an untranslated string. Human translations from GlotPress overwrite
# these on the next sync; the AI output is never pushed back to GlotPress.
#
# See the "Faster Releases" RFC, Phase 2 (continuous translations).
module AITranslator
  # Matches the Claude model already used elsewhere in CI (`.buildkite/claude-analysis.yml`).
  MODEL = :'claude-sonnet-4-6'
  # Keep batches small so each request's JSON response stays well under the
  # non-streaming token ceiling and a single failure costs little to retry.
  BATCH_SIZE = 40
  MAX_TOKENS = 8192

  module_function

  # Translates a set of strings, dropping any result whose placeholders don't
  # match the source (we never ship a translation that would break a `%@`).
  #
  # @param strings [Hash] `{ key => english_value }` to translate.
  # @param language_code [String] the `.lproj` locale code, e.g. `pt-BR`.
  # @param language_name [String] a human language name for the prompt, e.g. `Brazilian Portuguese`.
  # @return [Hash] `{ key => translation }` for entries that passed validation.
  def translate(strings:, language_code:, language_name:)
    return {} if strings.empty?

    # Required late so loading the Fastfile doesn't depend on the gem being
    # installed — only this lane needs it.
    require 'anthropic'
    client = Anthropic::Client.new # reads ANTHROPIC_API_KEY from the environment

    result = {}
    strings.each_slice(BATCH_SIZE) do |batch|
      batch_hash = batch.to_h
      raw = translate_batch(client: client, strings: batch_hash, language_code: language_code, language_name: language_name)
      result.merge!(validated_translations(raw, batch_hash, language_code))
    end
    result
  end

  # Keeps only the translations whose placeholders match the English source.
  def validated_translations(translations, english_by_key, language_code)
    translations.each_with_object({}) do |(key, translation), kept|
      english = english_by_key[key]
      next if english.nil? || translation.to_s.empty?

      if StringPlaceholders.compatible?(english, translation)
        kept[key] = translation
      else
        UI.message("Dropping #{language_code} translation for '#{key}' — placeholders changed")
      end
    end
  end

  def translate_batch(client:, strings:, language_code:, language_name:)
    message = client.messages.create(
      model: MODEL,
      max_tokens: MAX_TOKENS,
      messages: [{ role: 'user', content: prompt_for(strings: strings, language_code: language_code, language_name: language_name) }]
    )

    text = message.content.filter_map { |block| block.text if block.type == :text }.join
    parse_json_object(text)
  rescue StandardError => e
    # A best-effort backfill must never crash the daily job. Skip this batch
    # (those strings stay untranslated for now) and move on.
    UI.error("Claude translation request failed for #{language_code}: #{e.message}")
    {}
  end

  def prompt_for(strings:, language_code:, language_name:)
    <<~PROMPT
      Translate these iOS app UI strings from English to #{language_name} (locale code `#{language_code}`).

      Rules:
      - Preserve EVERY format specifier exactly: `%@`, `%1$@`, `%2$d`, `%%`, etc. Keep the same count, the same order, and the same positional indices (the `$` numbers).
      - Preserve leading and trailing whitespace and the surrounding punctuation style.
      - Keep translations concise and natural for a mobile UI.
      - Return ONLY a JSON object mapping each original key to its translation — no prose, no markdown, no code fences.

      Strings to translate (JSON object, key → English source):
      #{JSON.pretty_generate(strings)}
    PROMPT
  end

  # Extracts the JSON object from the model's response, tolerating any stray
  # prose or code fences despite the prompt asking for raw JSON.
  def parse_json_object(text)
    json = text[/\{.*\}/m]
    return {} if json.nil?

    parsed = JSON.parse(json)
    parsed.is_a?(Hash) ? parsed : {}
  rescue JSON::ParserError => e
    UI.error("Could not parse Claude response as JSON: #{e.message}")
    {}
  end
end
