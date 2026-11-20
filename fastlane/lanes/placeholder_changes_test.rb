# frozen_string_literal: true

# Pure-Ruby unit suite for PlaceholderChanges. Run directly: `ruby fastlane/lanes/placeholder_changes_test.rb`.
require 'minitest/autorun'
require_relative 'placeholder_changes'

# Exercises the check for English strings whose format arguments changed under an existing key.
class PlaceholderChangesTest < Minitest::Test
  P = PlaceholderChanges

  def test_unchanged_strings_have_no_changes
    strings = { 'a' => 'Hello %@', 'b' => '%d posts' }
    assert_empty P.incompatible(strings, strings)
  end

  def test_copy_change_without_argument_change_is_fine
    assert_empty P.incompatible({ 'a' => 'Hello %@' }, { 'a' => 'Hi there, %@!' })
  end

  def test_added_argument_is_flagged
    changes = P.incompatible({ 'a' => 'Saved' }, { 'a' => 'Saved %@' })
    assert_equal ['a'], changes.map(&:key)
    assert_equal 'Saved', changes.first.old_value
    assert_equal 'Saved %@', changes.first.new_value
    assert_includes changes.first.reason, 'before:'
    assert_includes changes.first.reason, 'after:'
  end

  def test_removed_argument_is_flagged
    assert_equal ['a'], P.incompatible({ 'a' => '%d posts' }, { 'a' => 'Posts' }).map(&:key)
  end

  def test_retyped_argument_is_flagged
    assert_equal ['a'], P.incompatible({ 'a' => '%@ posts' }, { 'a' => '%d posts' }).map(&:key)
  end

  def test_length_modifier_change_is_flagged
    # int vs long is a real ABI difference for an existing translation.
    assert_equal ['a'], P.incompatible({ 'a' => '%d posts' }, { 'a' => '%ld posts' }).map(&:key)
  end

  def test_swapped_bare_arguments_are_flagged
    # Existing translations of `%@: %d` read an object then an int; the new source passes an int then an object.
    assert_equal ['a'], P.incompatible({ 'a' => '%@: %d' }, { 'a' => '%d: %@' }).map(&:key)
  end

  def test_reordered_positional_arguments_are_fine
    assert_empty P.incompatible({ 'a' => '%1$@ invited %2$@' }, { 'a' => '%2$@ was invited by %1$@' })
  end

  def test_literal_percent_is_ignored
    assert_empty P.incompatible({ 'a' => '100%% done' }, { 'a' => 'All done' })
  end

  def test_new_and_removed_keys_are_ignored
    assert_empty P.incompatible({ 'old' => '%d posts' }, { 'new' => '%@ posts' })
  end

  def test_changes_are_sorted_by_key
    old_strings = { 'z' => '%d', 'a' => '%d', 'm' => 'same' }
    new_strings = { 'z' => '%@', 'a' => '%@', 'm' => 'same' }
    assert_equal %w[a z], P.incompatible(old_strings, new_strings).map(&:key)
  end
end
