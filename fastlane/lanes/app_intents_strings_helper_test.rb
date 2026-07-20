# frozen_string_literal: true

# Pure-Ruby unit suite for AppIntentsStrings.positionalize_untyped_arguments — the rewrite that turns the
# build-free extraction's untyped `%arg` placeholders into the positional printf specifiers GlotPress and the
# runtime expect. Run directly: `ruby fastlane/lanes/app_intents_strings_helper_test.rb`. No bundle / network.
require 'minitest/autorun'
require_relative 'app_intents_strings_helper'

# Pins the current behaviour of the placeholder rewrite, including the mixed-form numbering bug documented on
# the method. The `test_known_bug_*` cases assert what the code does today, NOT what it should do — they exist
# so a fix flips them deliberately rather than silently.
class AppIntentsStringsHelperTest < Minitest::Test
  def positionalize(value)
    AppIntentsStrings.positionalize_untyped_arguments(value)
  end

  def test_leaves_a_value_without_placeholders_untouched
    assert_equal 'Select Site', positionalize('Select Site')
  end

  def test_numbers_a_single_untyped_placeholder
    assert_equal 'Stats for %1$@', positionalize('Stats for %arg')
  end

  def test_numbers_untyped_placeholders_left_to_right
    assert_equal '%1$@ on %2$@', positionalize('%arg on %arg')
  end

  def test_preserves_an_explicit_position
    assert_equal '%1$@', positionalize('%1$arg')
  end

  def test_preserves_explicit_positions_out_of_order
    # Reordering is how translators adapt to a target language's word order, so it must survive the rewrite.
    assert_equal '%2$@ then %1$@', positionalize('%2$arg then %1$arg')
  end

  def test_an_escaped_percent_elsewhere_in_the_value_is_untouched
    assert_equal '100%% done: %1$@', positionalize('100%% done: %arg')
  end

  def test_leaves_an_already_typed_specifier_alone
    # `%@`/`%d` come from hand-written keys, not the untyped extraction, and are already GlotPress-ready.
    assert_equal '%1$@ of %2$d', positionalize('%1$@ of %2$d')
  end

  def test_does_not_match_arg_outside_a_placeholder
    assert_equal 'Largest argument', positionalize('Largest argument')
  end

  def test_known_bug_mixed_forms_renumber_onto_a_duplicate_index
    # The counter advances on the explicit `%2$arg` too, so the following untyped placeholder is numbered 2
    # as well: two placeholders collapse onto one argument. Should be '%2$@ and %1$@'.
    assert_equal '%2$@ and %2$@', positionalize('%2$arg and %arg')
  end

  def test_mixed_forms_are_correct_only_when_the_explicit_position_matches_the_counter
    # Same code path as the case above, but here the explicit `1$` happens to equal the counter, so the
    # output is right by coincidence — which is why the bug is easy to miss.
    assert_equal '%1$@ and %2$@', positionalize('%1$arg and %arg')
  end

  def test_known_bug_an_escaped_percent_before_arg_is_read_as_a_placeholder
    # `%%` is a literal percent, so "100%arg" is prose, not an interpolation — but the regex matches the
    # second `%` and swallows the word. Should be '100%%arg'.
    assert_equal '100%%1$@', positionalize('100%%arg')
  end
end
