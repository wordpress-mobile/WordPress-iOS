# frozen_string_literal: true

# Terminology configuration for the translator: brand/product names kept verbatim, plus per-locale glossary
# terms (the preferred translation for an English term) and a register/style note. A pure value object —
# SOURCING this data (the WordPress.org per-locale glossaries + style guides, a committed YAML, …) is
# pre-processing done elsewhere and handed in here, so this stays I/O-free and unit-testable.
class Glossary
  # Brand / product proper nouns kept verbatim in every locale. Deliberately tight to unambiguous proper nouns
  # — feature words locales legitimately translate ("Reader", "Stats") are intentionally NOT here.
  DEFAULT_DO_NOT_TRANSLATE = [
    'WordPress', 'WordPress.com', 'Jetpack', 'WooCommerce', 'Woo',
    'Akismet', 'Gravatar', 'Gutenberg', 'Tumblr', 'Simplenote', 'Crowdsignal'
  ].freeze

  attr_reader :do_not_translate

  # @param do_not_translate [Array<String>] brand/product names kept verbatim.
  # @param terms [Hash{String=>Hash{String=>String}}] locale => { english term => preferred translation }.
  # @param register [Hash{String=>String}] locale => style/register note (e.g. "Use the informal 'du' form.").
  def initialize(do_not_translate: DEFAULT_DO_NOT_TRANSLATE, terms: {}, register: {})
    @do_not_translate = do_not_translate
    @terms = terms
    @register = register
  end

  # The default brand-only glossary (no per-locale terms or register).
  def self.default
    new
  end

  # Prompt fragment with this locale's preferred terms + register note (or '' if neither applies). Appended to
  # the shared rules so the model uses the community's terminology and tone.
  def guidance(locale)
    [term_guidance(locale), register_note(locale)].reject(&:empty?).join("\n")
  end

  private

  def term_guidance(locale)
    pairs = @terms[locale]
    return '' if pairs.nil? || pairs.empty?

    lines = pairs.map { |english, translation| "  #{english} -> #{translation}" }
    "Use these exact translations for these terms, consistently:\n#{lines.join("\n")}"
  end

  def register_note(locale)
    note = @register[locale].to_s.strip
    note.empty? ? '' : "Register: #{note}"
  end
end
