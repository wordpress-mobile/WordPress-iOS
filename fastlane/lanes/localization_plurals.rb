# frozen_string_literal: true

require_relative 'plural_strings_helper'

#################################################
# Plurals: String Catalog ⇄ GlotPress ("all-flat")
#
# Plurals are authored in `WordPress/Classes/Plurals.xcstrings` (English one/other) and carried through the
# MAIN app GlotPress project as flat strings keyed `<key>|==|plural.<cldr-category>` — the same id Apple's
# `xcodebuild -exportLocalizations` uses — so every locale (incl. Welsh) is covered. The forward merges these
# flat originals into `Localizable.strings` (like MANUALLY_MAINTAINED_STRINGS_FILES); the reverse reads them
# back out of the downloaded `Localizable.strings` and folds them into the catalog JSON (build-free) via the
# committed per-locale category map. The flat keys stay in `Localizable.strings` as harmless, unused-at-runtime
# entries — exactly like the merged `infoplist.*` keys. The exporter is consulted only by
# `refresh_plural_categories` when the ship-locale list changes.
#################################################

# Lives in a synchronized source folder (WordPress/Classes) so it auto-joins the WordPress target.
# `WordPress/Resources` is an explicitly-referenced (non-synchronized) group, so a catalog placed
# there is NOT a target member and would be skipped by `-exportLocalizations`.
PLURALS_CATALOG        = File.join(PROJECT_ROOT_FOLDER, 'WordPress', 'Classes', 'Plurals.xcstrings')
PLURALS_FLAT_STRINGS   = File.join(PROJECT_ROOT_FOLDER, 'WordPress', 'Resources', 'Plurals.strings') # transient merge input (not committed)
# Per-locale CLDR category map ({ "<lproj>" => ["one","other",…] }): drives the build-free reverse (which slots
# each locale needs) and the forward union (which originals to upload). Captured from Apple's exporter (CLDR)
# over the 33 ship locales; regenerate with `refresh_plural_categories` when the supported-locale list changes.
PLURAL_CATEGORIES_JSON = File.join(PROJECT_ROOT_FOLDER, 'WordPress', 'Resources', 'plural-categories.json')
PLURALS_SCHEME         = 'WordPress'

platform :ios do
  # FORWARD (no build): Plurals.xcstrings (English) -> flat "<key>|==|plural.<cat>" originals (a transient
  # `.strings` that `generate_strings_file_for_glotpress` merges into Localizable.strings for the main project).
  #
  # Called by generate_strings_file_for_glotpress (its originals merge into Localizable.strings).
  desc 'Generates the flat plural originals (.strings) merged into Localizable.strings for GlotPress'
  lane :generate_plural_strings_for_glotpress do
    catalog = JSON.parse(File.read(PLURALS_CATALOG))
    categories = PluralStrings.union_categories(JSON.parse(File.read(PLURAL_CATEGORIES_JSON)))

    missing = PluralStrings.plural_keys_missing_other(catalog)
    unless missing.empty?
      UI.user_error!("Plurals.xcstrings: plural(s) missing a non-empty English `other` form (CLDR requires it — without it they upload empty originals): #{missing.join(', ')}")
    end

    originals = PluralStrings.flat_originals(catalog, categories)
    File.write(PLURALS_FLAT_STRINGS, PluralStrings.serialize_legacy_strings(originals))
    UI.message("Generated #{originals.size} flat plural originals from #{catalog['strings'].size} catalog keys → #{PLURALS_FLAT_STRINGS}")
  end

  # REVERSE (no build): pull the flat plural translations back out of the already-downloaded app
  # `Localizable.strings` (they rode the main GlotPress project) and fold them straight into Plurals.xcstrings
  # JSON, using the committed per-locale category map. Each cell is human ?? AI ?? English source; machine and
  # English-fallback cells are flagged needs_review.
  #
  # Called by download_localized_strings, after the app strings are downloaded.
  desc 'Folds plural translations from the downloaded Localizable.strings into Plurals.xcstrings'
  lane :download_localized_plurals do
    catalog = JSON.parse(File.read(PLURALS_CATALOG))
    missing = PluralStrings.plural_keys_missing_other(catalog)
    UI.user_error!("Plurals.xcstrings: plural(s) missing a non-empty English `other` form (CLDR requires it): #{missing.join(', ')}") unless missing.empty?
    categories_by_locale = JSON.parse(File.read(PLURAL_CATEGORIES_JSON))

    written = PluralStrings.fold_translations!(
      catalog,
      categories_by_locale: categories_by_locale,
      translations_by_locale: plural_translations_by_locale(File.join(PROJECT_ROOT_FOLDER, 'WordPress', 'Resources')),
      ai_translator: method(:ai_translate_plural)
    )
    File.write(PLURALS_CATALOG, "#{JSON.pretty_generate(catalog)}\n")
    UI.message("Folded plural translations from Localizable.strings into #{File.basename(PLURALS_CATALOG)} (#{written} locale variations).")

    git_commit(path: [PLURALS_CATALOG], message: 'Update plural translations from GlotPress', allow_nothing_to_commit: true)
  end

  # Regenerate the per-locale CLDR category map (`plural-categories.json`) from Apple's exporter over the ship
  # locales. Run only when the supported-locale list changes — the one place the exporter is used. Build-backed.
  desc 'Refreshes plural-categories.json (per-locale CLDR sets) from the exporter over the ship locales'
  lane :refresh_plural_categories do
    categories_by_locale = export_plural_skeletons(GLOTPRESS_TO_LPROJ_APP_LOCALE_CODES.values.uniq) do |skeleton_dir|
      paths = Dir.glob(File.join(skeleton_dir, '*.xcloc', 'Localized Contents', '*.xliff'))
      PluralStrings.categories_by_locale_from_skeletons(paths)
    end
    UI.user_error!('No plural categories found — is there a plural in Plurals.xcstrings?') if categories_by_locale.empty?

    File.write(PLURAL_CATEGORIES_JSON, "#{JSON.pretty_generate(categories_by_locale)}\n")
    UI.success("Wrote plural categories for #{categories_by_locale.size} locales: #{categories_by_locale.keys.sort.join(', ')}")
  end

  #################################################
  # Helpers
  #################################################

  # Exports the per-locale plural skeletons (one build) into a temp dir and yields it, removing the dir when
  # the block returns. Returns whatever the block returns.
  #
  # `SUPPORTS_MACCATALYST=NO` constrains the string-extraction build to iOS. Without it,
  # `-exportLocalizations` builds every supported destination incl. Mac Catalyst, which fails
  # when a binary dependency (e.g. a Zendesk xcframework) ships no `maccatalyst` slice.
  def export_plural_skeletons(xcode_locales)
    Dir.mktmpdir do |out|
      sh(
        'xcodebuild', '-exportLocalizations',
        '-workspace', WORKSPACE_PATH,
        '-scheme', PLURALS_SCHEME,
        '-localizationPath', out,
        'SUPPORTS_MACCATALYST=NO',
        *xcode_locales.flat_map { |loc| ['-exportLanguage', loc] }
      )
      yield out
    end
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

  # Machine-translation floor for the reverse fold: invoked for every plural slot with no human translation.
  # Returns nil until wired to a translation service, leaving such slots to fall back to the English source
  # (flagged needs_review). The named `category` + dev `note` let the prompt request the correct grammatical
  # form (e.g. "give me the Polish *few* form of …").
  # rubocop:disable Lint/UnusedMethodArgument -- keyword names are the documented call contract
  def ai_translate_plural(id:, source:, category:, note:, locale:)
    nil # TODO: call the translation service.
  end
  # rubocop:enable Lint/UnusedMethodArgument
end
