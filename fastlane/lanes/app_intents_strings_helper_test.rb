# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'app_intents_strings_helper'

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

  def test_mixed_forms_are_correct_when_the_explicit_position_matches_the_counter
    assert_equal '%1$@ and %2$@', positionalize('%1$arg and %arg')
  end

  # FAILING. Asserted as an invariant, not an exact string: which index the untyped placeholder should take
  # is the fixer's call, that it must not duplicate an explicit one is not.
  def test_no_two_placeholders_resolve_to_the_same_argument
    indices = positionalize('%2$arg and %arg').scan(/%(\d+)\$@/).flatten

    assert_equal indices.uniq, indices
  end

  # FAILING. `%%` is a literal percent, so "100%arg" is prose, not an interpolation.
  def test_an_escaped_percent_before_arg_is_not_a_placeholder
    assert_equal '100%%arg', positionalize('100%%arg')
  end
end
