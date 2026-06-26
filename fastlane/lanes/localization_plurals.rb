# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require_relative 'plural_strings_helper'

#################################################
# Plurals: String Catalog ⇄ GlotPress ("all-flat")
#
# Plurals are authored in `WordPress/Classes/Plurals.xcstrings` (English one/other) and carried through the
# main app GlotPress project as flat strings keyed `<key>|==|plural.<cldr-category>` — the same id Apple's
# `xcodebuild -exportLocalizations` uses — so every locale is covered. The forward merges these
# flat originals into `Localizable.strings` (like MANUALLY_MAINTAINED_STRINGS_FILES); the reverse reads them
# back out of the downloaded `Localizable.strings` and folds them into the catalog JSON. The flat keys stay in
# `Localizable.strings` as harmless, unused-at-runtime entries — exactly like the merged `infoplist.*` keys.
#
# Which CLDR categories each locale needs is Apple's to decide. The reverse derives that per-locale map fresh
# from the exporter at fold time — but from a throwaway one-plural Swift package, not the app (the categories
# are a property of the locale's CLDR, not our strings), so it's ~6s with no app build/bootstrap and can't lag
# the ship-locale list or Apple's CLDR. The forward needs no map: it emits the full CLDR set (the union over any
# real locale set is always all six), and over-emitting is harmless — the reverse folds only what each locale uses.
#################################################

# Lives in a synchronized source folder (WordPress/Classes) so it auto-joins the WordPress target.
# `WordPress/Resources` is an explicitly-referenced (non-synchronized) group, so a catalog placed
# there is NOT a target member and would be skipped by `-exportLocalizations`.
PLURALS_CATALOG        = File.join(PROJECT_ROOT_FOLDER, 'WordPress', 'Classes', 'Plurals.xcstrings')

# A throwaway one-plural String Catalog: exporting it per locale makes Apple emit that locale's CLDR plural
# categories. Those are a property of the locale, not of this content, so the stub yields the same per-locale
# sets as exporting the whole app — in seconds.
PLURAL_FIXTURE_CATALOG = {
  'sourceLanguage' => 'en', 'version' => '1.0',
  'strings' => { 'plural' => { 'localizations' => { 'en' => { 'variations' => { 'plural' => {
    'one' => { 'stringUnit' => { 'state' => 'translated', 'value' => '%lld item' } },
    'other' => { 'stringUnit' => { 'state' => 'translated', 'value' => '%lld items' } }
  } } } } } }
}.freeze

platform :ios do
  # FORWARD (no build): Plurals.xcstrings (English) -> flat "<key>|==|plural.<cat>" originals, RETURNED as a
  # `.strings` string (not written anywhere). `generate_strings_file_for_glotpress` writes it to a temp file
  # and merges it into Localizable.strings for the main project; run standalone it just prints a sample.
  #
  # Called by generate_strings_file_for_glotpress (its originals merge into Localizable.strings).
  desc 'Generates the flat plural originals (.strings) merged into Localizable.strings for GlotPress'
  lane :generate_plural_strings_for_glotpress do
    catalog = JSON.parse(File.read(PLURALS_CATALOG))

    missing = PluralStrings.plural_keys_missing_other(catalog)
    unless missing.empty?
      UI.user_error!("Plurals.xcstrings: plural(s) missing a non-empty English `other` form (CLDR requires it — without it they upload empty originals): #{missing.join(', ')}")
    end

    # Emit an original for every CLDR category. The union over any real ship-locale set is always all six
    # (Arabic/Welsh use them all), so there's no per-locale map to read here; over-emitting is harmless — the
    # reverse folds only the categories each locale actually needs.
    originals = PluralStrings.flat_originals(catalog, PluralStrings::CLDR_ORDER)
    text = PluralStrings.serialize_legacy_strings(originals)
    UI.message("Generated #{originals.size} flat plural originals from #{catalog['strings'].size} catalog keys.")
    UI.message("Sample:\n#{text.lines.first(6).join}")
    text
  end

  # REVERSE: pull the flat plural translations back out of the already-downloaded app `Localizable.strings`
  # (they rode the main GlotPress project) and fold them straight into Plurals.xcstrings JSON. Each cell is
  # human ?? AI ?? English source; machine and English-fallback cells are flagged needs_review. The per-locale
  # category map is derived fresh from the exporter (a ~6s throwaway-fixture export — see
  # `plural_categories_by_locale`), so it always matches the current ship locales and Apple's CLDR; the rest is
  # build-free JSON folding.
  #
  # Called by download_localized_strings, after the app strings are downloaded.
  desc 'Folds plural translations from the downloaded Localizable.strings into Plurals.xcstrings'
  lane :download_localized_plurals do
    catalog = JSON.parse(File.read(PLURALS_CATALOG))
    missing = PluralStrings.plural_keys_missing_other(catalog)
    UI.user_error!("Plurals.xcstrings: plural(s) missing a non-empty English `other` form (CLDR requires it): #{missing.join(', ')}") unless missing.empty?
    categories_by_locale = plural_categories_by_locale

    written = PluralStrings.fold_translations!(
      catalog,
      categories_by_locale: categories_by_locale,
      translations_by_locale: plural_translations_by_locale(File.join(PROJECT_ROOT_FOLDER, 'WordPress', 'Resources')),
      ai_translator: plural_ai_translator
    )
    File.write(PLURALS_CATALOG, "#{JSON.pretty_generate(catalog)}\n")
    UI.message("Folded plural translations from Localizable.strings into #{File.basename(PLURALS_CATALOG)} (#{written} locale variations).")

    git_commit(path: [PLURALS_CATALOG], message: 'Update plural translations from GlotPress', allow_nothing_to_commit: true)
  end

  #################################################
  # Helpers
  #################################################

  # Per-locale CLDR category map, derived fresh from Apple's exporter over the ship locales — but from a
  # THROWAWAY one-plural Swift package, not the app, so it's ~6s with no app build/bootstrap (the categories
  # are a property of the locale's CLDR, not the catalog's content). Derived at fold time, so it can't lag the
  # ship-locale list or Apple's CLDR. @return [Hash{String=>Array<String>}] lproj => CLDR categories.
  def plural_categories_by_locale
    Dir.mktmpdir do |package_dir|
      write_plural_category_fixture(package_dir)
      Dir.mktmpdir do |export_dir|
        langs = GLOTPRESS_TO_LPROJ_APP_LOCALE_CODES.values.uniq.flat_map { |loc| ['-exportLanguage', loc] }
        Dir.chdir(package_dir) do
          sh('xcodebuild', '-exportLocalizations', '-localizationPath', export_dir, *langs)
        end
        paths = Dir.glob(File.join(export_dir, '*.xcloc', 'Localized Contents', '*.xliff'))
        categories = PluralStrings.categories_by_locale_from_skeletons(paths)
        UI.user_error!('No plural categories captured from the exporter') if categories.empty?
        categories
      end
    end
  end

  # Writes the throwaway one-plural Swift package the exporter is run against.
  def write_plural_category_fixture(dir)
    sources = File.join(dir, 'Sources', 'PluralCategories')
    FileUtils.mkdir_p(sources)
    File.write(File.join(dir, 'Package.swift'), <<~SWIFT)
      // swift-tools-version:5.9
      import PackageDescription
      let package = Package(name: "PluralCategories", defaultLocalization: "en",
        targets: [.target(name: "PluralCategories", resources: [.process("Localizable.xcstrings")])])
    SWIFT
    File.write(File.join(sources, 'PluralCategories.swift'), "let placeholder = 0\n")
    File.write(File.join(sources, 'Localizable.xcstrings'), JSON.generate(PLURAL_FIXTURE_CATALOG))
  end

  # Pulls the flat plural keys out of each locale's downloaded `Localizable.strings`, returning
  # { "<lproj>" => { "<flat-plural-id>" => value } }. Decoding (escapes like `\n`/`\U…`, encoding/BOM) is
  # delegated to `L10nHelper.read_strings_file_as_hash` — Apple's `plutil` — rather than a hand-rolled parser.
  def plural_translations_by_locale(dir)
    Dir.glob(File.join(dir, '*.lproj', 'Localizable.strings')).each_with_object({}) do |path, acc|
      locale = File.basename(File.dirname(path), '.lproj')
      translations = Fastlane::Helper::Ios::L10nHelper.read_strings_file_as_hash(path: path)
      acc[locale] = translations.select { |key, _| PluralStrings.plural_key?(key) }
    end
  end

  # The machine-translation tier for the reverse fold (the AI rung of the `human ?? AI ?? English` floor), or
  # nil when ANTHROPIC_API_KEY isn't configured — in which case untranslated plural cells keep falling back to
  # the English source (flagged needs_review), exactly as before this was wired. Built once and reused for
  # every (key, locale) form-set.
  #
  # The returned callable matches PluralStrings.fold_translations!'s form-set contract and is wrapped to
  # DEGRADE, not crash. Two failure modes, both non-fatal: a per-set API error logs and returns {} so that one
  # set falls back to English while the rest of the fold proceeds and commits; a setup error — the gem missing
  # (LoadError) or the client failing to construct (any StandardError, e.g. a malformed ANTHROPIC_BASE_URL) —
  # logs and returns nil, disabling the AI tier for this run while the human/English fold still proceeds and
  # commits (rather than dropping the whole reverse step). The reverse step is additionally guarded by
  # `run_plural_step`. Going through `AITranslator#translate_plural` — the whole form-set in one request — keeps
  # one consistent word/stem across the forms (a per-cell call lets the model drift between synonyms, e.g.
  # Polish słowo → wyrazy → słów).
  def plural_ai_translator
    if ENV['ANTHROPIC_API_KEY'].to_s.empty?
      UI.important('ANTHROPIC_API_KEY not set — skipping AI plural translation; untranslated plurals fall back to English (needs_review).')
      return nil
    end

    require_relative 'ai_translator'
    translator = AITranslator.with_anthropic
    lambda do |english_forms:, categories:, locale:, note:, anchors:|
      translator.translate_plural(english_forms: english_forms, categories: categories, locale: locale, note: note, anchors: anchors)
    rescue StandardError => e
      UI.error("AI plural translation failed for #{locale} (#{e.message}); falling back to English for this form-set.")
      {}
    end
  rescue LoadError, StandardError => e
    UI.important("AI translation tier unavailable (#{e.message}); untranslated plurals fall back to English.")
    nil
  end
end
