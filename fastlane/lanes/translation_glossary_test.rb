# frozen_string_literal: true

# Pure-Ruby unit suite for Glossary. Run directly: `ruby fastlane/lanes/translation_glossary_test.rb`.
require 'minitest/autorun'
require_relative 'translation_glossary'

# Covers the brand list, per-locale term guidance, register note, the combination, and empty cases.
class GlossaryTest < Minitest::Test
  def test_default_is_brands_only
    glossary = Glossary.default
    assert_includes glossary.do_not_translate, 'WordPress'
    assert_equal '', glossary.guidance('fr')
  end

  def test_term_guidance_is_per_locale
    glossary = Glossary.new(terms: { 'fr' => { 'post' => 'article', 'tag' => 'étiquette' } })
    assert_includes glossary.guidance('fr'), 'post -> article'
    assert_includes glossary.guidance('fr'), 'tag -> étiquette'
    assert_equal '', glossary.guidance('de') # no terms for de
  end

  def test_register_note
    glossary = Glossary.new(register: { 'de' => "Use the informal 'du' form." })
    assert_includes glossary.guidance('de'), "Register: Use the informal 'du' form."
  end

  def test_terms_and_register_combined
    glossary = Glossary.new(terms: { 'fr' => { 'post' => 'article' } }, register: { 'fr' => 'Use formal vous.' })
    guidance = glossary.guidance('fr')
    assert_includes guidance, 'post -> article'
    assert_includes guidance, 'Register: Use formal vous.'
  end

  def test_custom_do_not_translate
    assert_equal %w[Foo Bar], Glossary.new(do_not_translate: %w[Foo Bar]).do_not_translate
  end
end
