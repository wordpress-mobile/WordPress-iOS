# frozen_string_literal: true

# Pure-Ruby unit suite for CatalogHelper.reworded_keys — the immutable-key guard that detects an explicit-key
# string whose English source was reworded in place (which `xcstringstool sync` silently ignores, leaving stale
# translations). Run directly: `ruby fastlane/lanes/catalog_helper_test.rb`. No bundle / network.
require 'minitest/autorun'
require_relative 'catalog_helper'

# Exercises the reword detector (an explicit-key string whose stored English differs from a fresh extraction is
# flagged; key-as-source, variations/plural, unchanged, and removed keys are not) and the coverage compare.
class CatalogHelperTest < Minitest::Test
  def en(value)
    { 'localizations' => { 'en' => { 'stringUnit' => { 'state' => 'translated', 'value' => value } } } }
  end

  def reworded(strings, current_en)
    CatalogHelper.reworded_keys({ 'sourceLanguage' => 'en', 'version' => '1.0', 'strings' => strings }, current_en)
  end

  def test_flags_an_explicit_key_whose_english_changed_in_place
    assert_equal ['common.save'], reworded({ 'common.save' => en('Save') }, { 'common.save' => 'Save all' })
  end

  def test_does_not_flag_an_unchanged_key
    assert_empty reworded({ 'common.save' => en('Save') }, { 'common.save' => 'Save' })
  end

  def test_does_not_flag_a_key_absent_from_the_fresh_extraction
    # The key was removed/renamed in code — sync handles that as stale; it is not an in-place reword.
    assert_empty reworded({ 'common.save' => en('Save') }, {})
  end

  def test_does_not_flag_a_key_as_source_entry
    # No stored `en` value (the key IS the English); rewording it changes the key, so it can't appear here.
    assert_empty reworded({ '%1$@ on %2$@' => {} }, { '%1$@ on %2$@' => '%1$@ at %2$@' })
  end

  def test_does_not_flag_a_variations_shaped_english
    # English stored under `variations` has no flat `en` stringUnit value, so it can never read as a reword.
    varied = { 'localizations' => { 'en' => { 'variations' => { 'device' => { 'iphone' => { 'stringUnit' => { 'state' => 'translated', 'value' => 'Tap' } } } } } } }
    assert_empty reworded({ 'app.banner' => varied }, { 'app.banner' => 'Click' })
  end

  def test_reports_every_reworded_key
    strings = { 'a' => en('One'), 'b' => en('Two'), 'c' => en('Three') }
    assert_equal %w[b c], reworded(strings, { 'a' => 'One', 'b' => 'TWO', 'c' => 'THREE' }).sort
  end

  # coverage_gap must not conflate keys that differ only in argument TYPE. `canonical` used to replace every format
  # specifier with one sentinel regardless of type/index, so if the build-free extraction loses "%d days" (e.g. a
  # same-basename .stringsdata overwrite — the exact regression this gate exists to catch), the surviving "%@ days"
  # masked it. "%d days" (int) and "%@ days" (object) are real, distinct en.lproj keys; dropping either is a hole.
  def test_coverage_gap_does_not_conflate_distinct_type_sibling_keys
    assert_equal ['%d days'], CatalogHelper.coverage_gap(['%d days', '%@ days'], ['%@ days'])
  end
end
