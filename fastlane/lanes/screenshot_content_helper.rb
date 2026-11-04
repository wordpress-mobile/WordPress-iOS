# frozen_string_literal: true

require 'fileutils'
require 'json'

# Translates the content of the Jetpack UI test fixtures for the App Store screenshots.
#
# The screenshots run against the fixtures in `Tests/JetpackUITests/Fixtures`, whose content is in
# English. For each language, this writes an overlay: a copy of every mapping file that has text to
# translate, with that text translated. The app loads it over the fixtures, replacing the files at
# the same paths (see `FixtureSet`), so the UI tests' fixtures stay as they are.
#
# The text to translate is a table of keys and the English exactly as it appears in the fixtures,
# and each language has a table with the same keys. Every string value in a mapping is translated:
#
# - An entry that's a phrase of a few words or more is replaced wherever it appears in a value, such
#   as a paragraph inside a post's HTML.
# - A shorter entry, such as a post called "Home", only replaces a value that's exactly that, so it
#   can't change a word inside some other text.
#
# Longer entries are applied first, so a sentence is translated as a whole before a title in it is.
#
# Notifications mark parts of their text, such as a name or a post's title, with ranges of UTF-16
# offsets. When a notification's text is translated, each range is moved to where its part is in the
# translation, and a translation that's left a part out is an error, since the notification would
# then mark the wrong text.
#
# Run directly to try it on the real fixtures:
#   ruby fastlane/lanes/screenshot_content_helper.rb <fixtures> <english.json> <translated.json> <output>
module ScreenshotContentHelper
  # A translation that left out a part of a notification's text that one of its ranges marks.
  class MissingRangeError < StandardError; end

  # Text as UTF-16 code units, which is how notification ranges count: the app makes them `NSRange`s.
  module UTF16Text
    module_function

    def units(text)
      text.encode('UTF-16LE').unpack('v*')
    end

    def string(units)
      units.pack('v*').force_encoding('UTF-16LE').encode('UTF-8')
    end

    # The offsets at which `part` starts in `units`.
    def occurrences(units, part)
      return [] if part.empty?

      (0..(units.length - part.length)).select { |index| units[index, part.length] == part }
    end

    # Which occurrence of `part` in `units` starts at `offset`, counting from 0.
    def occurrence(units, part, offset)
      occurrences(units, part).index(offset) || 0
    end
  end

  # The shortest phrase that's replaced inside other text, rather than only as a whole value.
  MINIMUM_PHRASE_LENGTH = 12

  module_function

  # Writes the overlay for one language to `output`, and returns the paths it wrote, relative to the
  # `mappings` directory.
  #
  # @param fixtures [String] The directory that contains the fixtures' `mappings` directory.
  # @param english [Hash{String => String}] The text to translate, by key.
  # @param translated [Hash{String => String}] The translations, by the same keys. A key it doesn't
  #   have is left in English.
  # @param output [String] The directory to write the overlay to. It's emptied first.
  def write_overlay(fixtures:, english:, translated:, output:)
    replacements = replacements(english: english, translated: translated)
    mappings = File.join(fixtures, 'mappings')

    FileUtils.rm_rf(output)
    Dir.glob('**/*.json', base: mappings).sort.filter_map do |path|
      translated_mapping = translated_mapping(File.read(File.join(mappings, path)), replacements, path)
      next if translated_mapping.nil?

      destination = File.join(output, 'mappings', path)
      FileUtils.mkdir_p(File.dirname(destination))
      File.write(destination, "#{JSON.pretty_generate(translated_mapping)}\n")
      path
    end
  end

  # The pairs of English and translation to replace, longest first, leaving out what isn't translated.
  def replacements(english:, translated:)
    pairs = english.filter_map do |key, from|
      to = translated[key]
      [from, to] unless to.nil? || to.empty? || to == from
    end
    pairs.sort_by { |from, _| -from.length }
  end

  # The keys a translation table is missing, or has that the English one doesn't.
  def mismatched_keys(english:, translated:)
    { missing: english.keys - translated.keys, unknown: translated.keys - english.keys }
  end

  # A mapping file's contents with its text translated, or nil when it has nothing to translate.
  def translated_mapping(source, replacements, path)
    # A quick check before parsing: the English as it reads in a JSON value, or in a body that's
    # itself a string of JSON, which escapes it twice.
    return nil unless replacements.any? { |from, _| source.include?(json_escaped(from)) || source.include?(json_escaped(json_escaped(from))) }

    mapping = JSON.parse(source)
    translated = translate_mapping(mapping, replacements, path)
    translated == mapping ? nil : translated
  end

  def translate_mapping(mapping, replacements, path)
    body = mapping.dig('response', 'body')
    return translate_value(mapping, replacements, path) unless body.is_a?(String)

    translated = translate_value(mapping.merge('response' => mapping['response'].except('body')), replacements, path)
    translated['response']['body'] = translate_body(body, replacements, path)
    translated
  end

  # A body written as a string of JSON is translated as JSON, so its values are escaped properly.
  # One that isn't JSON, such as one with template expressions, has its text replaced directly.
  def translate_body(body, replacements, path)
    JSON.generate(translate_value(JSON.parse(body), replacements, path))
  rescue JSON::ParserError
    replacements.reduce(body) { |text, (from, to)| phrase?(from) ? text.gsub(json_escaped(from), json_escaped(to)) : text }
  end

  def translate_value(value, replacements, path)
    case value
    when Hash then translate_hash(value, replacements, path)
    when Array then value.map { |child| translate_value(child, replacements, path) }
    when String then translate_string(value, replacements)
    else value
    end
  end

  def translate_hash(hash, replacements, path)
    translated = hash.transform_values { |child| translate_value(child, replacements, path) }
    move_ranges(hash, translated, replacements, path) if hash['text'].is_a?(String) && hash['ranges'].is_a?(Array)
    translated
  end

  def translate_string(text, replacements)
    replacements.reduce(text) do |result, (from, to)|
      if phrase?(from)
        result.gsub(from, to)
      else
        result == from ? to : result
      end
    end
  end

  # Moves each of a notification block's ranges to where the part it marks is in the translated text.
  def move_ranges(original, translated, replacements, path)
    texts = { old: UTF16Text.units(original['text']), new: UTF16Text.units(translated['text']) }
    translated['ranges'].each do |range|
      start, finish = range['indices']
      next unless start.is_a?(Integer) && finish.is_a?(Integer)

      range['indices'] = moved_indices(texts, start...finish, replacements) do |part|
        raise MissingRangeError, "#{path}: the translation of #{original['text'].inspect} has no #{part.inspect}, " \
                                 'which the notification marks. Keep it in the translation, exactly as it is translated on its own.'
      end
    end
  end

  # Where the part of the old text at `range` is in the new text, translated. Yields the translated
  # part when it isn't there.
  def moved_indices(texts, range, replacements)
    part = texts[:old][range]
    # Which occurrence of the part this is, in case it appears more than once.
    occurrence = UTF16Text.occurrence(texts[:old], part, range.begin)
    translated_part = UTF16Text.units(translate_string(UTF16Text.string(part), replacements))
    start = UTF16Text.occurrences(texts[:new], translated_part)[occurrence]
    yield UTF16Text.string(translated_part) if start.nil?
    [start, start + translated_part.length]
  end

  def phrase?(text)
    text.length >= MINIMUM_PHRASE_LENGTH && text.include?(' ')
  end

  def json_escaped(text)
    JSON.generate(text)[1...-1]
  end
end

if $PROGRAM_NAME == __FILE__
  fixtures, english, translated, output = ARGV
  abort "Usage: ruby #{__FILE__} <fixtures> <english.json> <translated.json> <output>" if output.nil?
  written = ScreenshotContentHelper.write_overlay(
    fixtures: fixtures,
    english: JSON.parse(File.read(english)),
    translated: JSON.parse(File.read(translated)),
    output: output
  )
  puts written
end
