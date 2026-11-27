# frozen_string_literal: true

require_relative 'translation_validator'

# Finds English strings whose format arguments changed while their key stayed the same.
#
# Translations are matched to their English source by key. If a key keeps its name but its English text gains,
# loses, or retypes a format argument (`%@` → `%d`), every existing translation of that key still carries the OLD
# arguments. The app then formats the old translation with the NEW arguments and reads the wrong value off the
# stack — a crash or garbage text, in a language the author can't read. The fix is always the same: give the
# changed text a new key, so it starts untranslated instead of mistranslated.
#
# `upload_strings_for_translation` runs this before it sends new English text to GlotPress, so the change is
# caught on the trunk build that introduced it. New and removed keys are fine. Reordering positional arguments
# (`%1$@ … %2$@` → `%2$@ … %1$@`) is fine too, because translations bind arguments by index.
#
# Plain Ruby with no dependencies, so it can be unit-tested directly.
module PlaceholderChanges
  module_function

  Change = Struct.new(:key, :old_value, :new_value, :reason, keyword_init: true)

  # @param old_strings [Hash{String=>String}] the English strings before the change, by key.
  # @param new_strings [Hash{String=>String}] the English strings after the change, by key.
  # @return [Array<Change>] the keys present in both whose format arguments differ, sorted by key.
  def incompatible(old_strings, new_strings)
    (old_strings.keys & new_strings.keys).sort.filter_map do |key|
      reason = TranslationValidator.mismatch_reason(old_strings[key], new_strings[key])
      next unless reason

      # The validator words its reason for a source and its translation; here it's the old and new English.
      reason = reason.gsub('source:', 'before:').gsub('translation:', 'after:')

      Change.new(key: key, old_value: old_strings[key], new_value: new_strings[key], reason: reason)
    end
  end
end
