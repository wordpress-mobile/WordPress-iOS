# frozen_string_literal: true

require 'json'
require 'open3'

# Compares the placeholder "shape" — the count, position, and argument type of
# the format specifiers — of localized strings.
#
# Used in two places in the "Faster Releases" RFC, Phase 2 (continuous
# translations):
#   1. The localization guardrail: an existing key's English value must not
#      change its placeholders without getting a new key, or existing
#      translations would silently break.
#   2. Validating AI-backfilled translations: a machine translation that drops
#      or reorders a `%@` / `%1$d` must be rejected rather than shipped.
module StringPlaceholders
  # printf / NSString conversion characters grouped by the argument type a
  # translator must preserve. `%d` <-> `%i` is fine (same int arg); `%d` <-> `%@`
  # is not (int vs object).
  CONVERSION_CLASSES = {
    '@' => 'object',
    'd' => 'int', 'i' => 'int', 'u' => 'int', 'o' => 'int', 'x' => 'int', 'X' => 'int',
    'f' => 'float', 'e' => 'float', 'E' => 'float', 'g' => 'float', 'G' => 'float', 'a' => 'float', 'A' => 'float',
    'c' => 'char', 'C' => 'char',
    's' => 'cstring', 'S' => 'cstring',
    'p' => 'pointer'
  }.freeze

  # A single format specifier: optional positional arg (`1$`), flags, width,
  # precision, length modifier, then the conversion character. `%%` (literal
  # percent) is matched too, so it can be explicitly skipped.
  SPECIFIER = /%(?<position>\d+\$)?[-+ 0#]*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|h|ll|l|q|L|z|t|j)?(?<conversion>[@diouxXeEfgGaAcCsSpn%])/

  module_function

  # Parses a `.strings` file into a `{ key => value }` hash using `plutil`
  # (`.strings` is an old-style property list, and `plutil` is the most reliable
  # parser for it — handling escapes, comments, and Unicode).
  def parse_file(path)
    raise "File not found: #{path}" unless File.exist?(path)

    json, stderr, status = Open3.capture3('plutil', '-convert', 'json', '-o', '-', path)
    raise "Failed to parse #{path} with plutil:\n#{stderr}" unless status.success?

    JSON.parse(json)
  end

  # A canonical signature of the placeholders in a string value, or '' if there
  # are none. Two values with the same signature are placeholder-compatible.
  def signature(value)
    specifiers = []
    value.to_s.scan(SPECIFIER) do
      match = Regexp.last_match
      conversion = match[:conversion]
      next if conversion == '%' # literal percent, not a placeholder

      position = match[:position]&.delete('$')&.to_i
      specifiers << { position: position, klass: CONVERSION_CLASSES.fetch(conversion, conversion) }
    end

    return '' if specifiers.empty?

    if specifiers.all? { |s| s[:position] }
      # Positional args (`%1$@`): compare the position -> type mapping.
      specifiers.sort_by { |s| s[:position] }.map { |s| "#{s[:position]}:#{s[:klass]}" }.join(',')
    elsif specifiers.none? { |s| s[:position] }
      # Non-positional args: compare types in order of appearance.
      specifiers.map { |s| s[:klass] }.join(',')
    else
      # Mixed positional/non-positional is unusual; be conservative and keep both.
      specifiers.map { |s| "#{s[:position] || '_'}:#{s[:klass]}" }.join(',')
    end
  end

  # Whether two string values share the same placeholder shape.
  def compatible?(old_value, new_value)
    signature(old_value) == signature(new_value)
  end

  # Given two `{ key => value }` hashes, returns the keys present in BOTH whose
  # placeholder signature changed, as an array of detail hashes. New and removed
  # keys are ignored on purpose — copy that needs a fresh translation is expected
  # to land under a new key (which shows up as remove-old + add-new).
  def incompatible_changes(old_strings, new_strings)
    (old_strings.keys & new_strings.keys).sort.filter_map do |key|
      old_signature = signature(old_strings[key])
      new_signature = signature(new_strings[key])
      next if old_signature == new_signature

      { key: key, old: old_strings[key], new: new_strings[key], old_signature: old_signature, new_signature: new_signature }
    end
  end
end
