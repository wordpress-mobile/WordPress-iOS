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

  # A NON-positional source (%@ … %@) whose translation reorders via positional specifiers (%2$@ … %1$@) is the
  # standard, Apple-documented iOS way to reorder arguments for target grammar: String(format:) honors positional
  # specifiers regardless of the source's shape, and each specifier still reads an argument of the same type. So
  # this must be ACCEPTED, exactly like the already-positional reorder above. The gate currently rejects it,
  # because it compares the source's positional/sequential views independently and a bare-%@ source has an empty
  # positional map. This is not academic: real GlotPress data has 23 key-as-source strings across 34 locales
  # (513 shipping cells) that positionalize a bare-%@ English source this way — e.g. the Arabic
  # "%@ of %@ used on your site" => "%1$@ من %2$@ على موقعك". The human-translation gate this catalog work adds
  # (CatalogStrings.trusted_human, PluralStrings.human_forms_for) rejects every one of them and downgrades a
  # valid, currently-shipping human translation to machine/English.
  #
  # (Genuine breakage stays rejected by the existing tests: a sequential flip `%@: %d` => `%d : %@` and a type
  # change are still caught, so a correct fix cannot simply ignore the positional/sequential distinction.)
  def test_positionalizing_a_non_positional_source_to_reorder_is_allowed
    assert V.placeholders_match?('%@ - %@', '%2$@ - %1$@') # two objects, reordered
    assert V.placeholders_match?('%@. %d posts.', '%1$@. %2$d posts.') # object + int, positionalized in place
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

  # --- Failing tests: gaps surfaced by the pipeline-breaker audit (currently RED; each documents a real defect
  #     where the gate violates its own "same count, same types, same index→type mapping" invariant) -----------

  # A candidate that binds the SAME positional index to two different types (%1$@ then %1$d) changes the argument
  # contract: at runtime String(format:) reads argument 1 as an OBJECT for %1$@, but the source only ever supplies
  # an int there — a wrong-vararg read (crash / garbage). The gate must reject it. It currently does NOT, because
  # signature() stores specifiers in a Hash keyed by index with plain assignment, so %1$d silently OVERWRITES
  # %1$@ at index 1 (last-wins), collapsing the type conflict to {1 => int}. This PR's implied_positional widened
  # the blast radius: a bare-specifier source like `%d` now normalizes to {1 => int} and matches the collapsed
  # candidate, so the first case below regressed from reject (pre-PR) to accept.
  def test_duplicate_positional_index_with_conflicting_type_is_rejected
    refute V.placeholders_match?('%d', '%1$@ %1$d')               # regressed by implied_positional (rejected pre-PR)
    refute V.placeholders_match?('%1$d words', '%1$@ %1$d words') # pre-existing last-wins collapse at index 1
  end

  # Dynamic field width / precision (`*`) consumes an EXTRA int vararg before the value: `%*d` reads a width int
  # then the int value (two args); `%.*f` reads a precision int then the double (two args). The gate matches the
  # `*` in the FORMAT_SPECIFIER regex but never emits an argument token for it, so `%d` and `%*d` (and `%.*f` vs
  # `%.2f`) reduce to the identical signature — an arg-count mismatch it must catch per its own "same count"
  # invariant. Both currently accepted. No shipping source uses `%*` today, so this is latent, not live.
  def test_dynamic_width_precision_star_is_counted
    refute V.placeholders_match?('%d posts', '%*d posts')      # candidate reads one int past what the source supplies
    refute V.placeholders_match?('Value: %.*f', 'Value: %.2f') # source consumes precision-int + double; candidate one
  end
end
