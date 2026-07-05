# frozen_string_literal: true

# Pure-Ruby unit suite for TranslationValidator. Run directly: `ruby fastlane/lanes/translation_validator_test.rb`.
require 'minitest/autorun'
require_relative 'translation_validator'

# Exercises the format-specifier contract: positional reordering allowed, type/length/count changes rejected.
class TranslationValidatorTest < Minitest::Test
  V = TranslationValidator

  def test_no_specifiers_anything_matches
    assert V.placeholders_match?('Settings', 'Réglages')
    assert V.placeholders_match?('', '')
  end

  def test_positional_reordering_is_allowed
    # Reordering %1$@ / %2$@ to suit target grammar is the whole point of positional specifiers.
    assert V.placeholders_match?('%1$@ invited %2$@', '%2$@ wurde von %1$@ eingeladen')
  end

  def test_positional_type_change_is_rejected
    # %1$@ (object) → %1$d (int) would read the wrong vararg — a crash vector.
    refute V.placeholders_match?('%1$@ posts', '%1$d posts')
  end

  def test_sequential_order_must_be_preserved
    refute V.placeholders_match?('%@: %d', '%d : %@') # flipped non-positional args
    assert V.placeholders_match?('%@: %d', 'Total %@: %d') # same order, prose changed
  end

  def test_count_mismatch_is_rejected
    refute V.placeholders_match?('Hello %@', 'Bonjour') # dropped an argument
    refute V.placeholders_match?('Hello %@', 'Bonjour %@ %@') # added an argument
  end

  def test_literal_percent_is_ignored
    assert V.placeholders_match?('100% done', '100% terminé') # no real specifier (space after %)
    assert V.placeholders_match?('%d%% complete', '%d%% terminé') # %% literal, %d preserved
    refute V.placeholders_match?('%d%% complete', '%% terminé') # dropped the %d argument
  end

  def test_length_modifier_change_is_rejected
    # %ld (long) → %d (int) is a genuine ABI difference that can crash on mismatch.
    refute V.placeholders_match?('%1$ld words', '%1$d words')
    assert V.placeholders_match?('%1$ld words', '%1$ld mots')
  end

  def test_case_only_conversion_change_is_allowed
    assert V.placeholders_match?('%x', '%X') # cosmetic; same integer type-class
  end

  def test_mismatch_reason_is_descriptive
    reason = V.mismatch_reason('%1$@ posts', '%1$d posts')
    refute_nil reason
    assert_includes reason, 'positional'

    assert_nil V.mismatch_reason('%1$@ invited %2$@', '%2$@ a invité %1$@')
  end
end
