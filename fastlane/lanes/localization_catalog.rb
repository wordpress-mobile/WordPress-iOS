# frozen_string_literal: true

require 'json'
require 'tmpdir'
require 'fileutils'
require_relative 'catalog_helper'

#################################################
# Catalog generation (forward / extraction)
#
# Build-free replacement for the genstrings step: extract the app's English source strings into a
# String Catalog using Apple's own `xcstringstool extract` + `sync` (not a full app build). This is the
# first step of moving the localization backing store to String Catalogs for the AI translation pipeline.
#
# `xcstringstool extract --legacy-localizable-strings --modern-localizable-strings -s AppLocalizedString`
# recognizes NSLocalizedString + ObjC siblings (legacy), `String(localized:)`/`LocalizedStringResource`
# (modern — so catalog-native code is covered the moment it's written), and the app's custom
# `AppLocalizedString` routine (the same `-s` flag genstrings uses today — call sites stay unchanged).
# `sync` then merges all the extracted `.stringsdata` (every source that targets the Localizable table) into
# the one catalog, deduped by key, applying the per-string state machine (new / extracted_with_value / stale).
#
# Note: this lane only generates the English-source catalog as the future backing store. It writes to a
# non-synchronized folder so it is not yet a build member (the runtime still uses the committed
# `Localizable.strings`). Wiring the catalog into the target and retiring the legacy `.strings` is a separate
# migration step.
#################################################

# Generated English-source catalog (Localizable table). In WordPress/Resources (non-synced) so it is produced
# as an artifact without auto-joining the target / conflicting with the existing Localizable.strings.
LOCALIZABLE_CATALOG = File.join(PROJECT_ROOT_FOLDER, 'WordPress', 'Resources', 'Localizable.xcstrings')

# Source roots to extract from — mirrors `generate_strings_file`'s genstrings inputs.
CATALOG_SOURCE_ROOTS = [
  File.join(PROJECT_ROOT_FOLDER, 'WordPress'),
  File.join(PROJECT_ROOT_FOLDER, 'Modules', 'Sources')
].freeze

# The custom localization routine to additionally extract (same as the genstrings `routines:` today).
CATALOG_LOCALIZATION_ROUTINE = 'AppLocalizedString'

platform :ios do
  # Extracts English source strings from code into Localizable.xcstrings (build-free; replaces genstrings).
  #
  # @option gutenberg_path [String] Optional path to a Gutenberg source clone to also extract from
  #   (Gutenberg ships as a binary XCFramework, so its source must be cloned — same as the legacy lane).
  desc 'Generates Localizable.xcstrings from source via xcstringstool extract + sync (build-free)'
  lane :generate_strings_catalog do |gutenberg_path: nil, swiftui: false|
    roots = CATALOG_SOURCE_ROOTS + [gutenberg_path].compact
    files = catalog_source_files(roots)
    UI.user_error!('No source files found to extract from') if files.empty?
    UI.message("Extracting localizable strings from #{files.count} source files in #{roots.count} roots…")

    Dir.mktmpdir do |stringsdata_dir|
      extract_stringsdata(files: files, output_dir: stringsdata_dir, swiftui: swiftui)
      synced = sync_localizable_catalog(stringsdata_dir: stringsdata_dir)
      reconciled = reconcile_changed_sources(stringsdata_dir: stringsdata_dir)
      report_catalog(LOCALIZABLE_CATALOG, extracted_count: synced, reconciled_count: reconciled)
    end
  end

  # Verifies the generated catalog captures every string the legacy genstrings flow finds over the SAME
  # source files — the safety net proving the build-free extraction loses nothing, and guarding against
  # regressions like the same-basename `.stringsdata` collision. Fails listing any string only genstrings found.
  desc 'Verifies Localizable.xcstrings covers every string genstrings extracts (coverage gate)'
  lane :verify_strings_catalog do |gutenberg_path: nil|
    UI.user_error!("#{LOCALIZABLE_CATALOG} not found — run generate_strings_catalog first") unless File.exist?(LOCALIZABLE_CATALOG)
    files = catalog_source_files(CATALOG_SOURCE_ROOTS + [gutenberg_path].compact)

    Dir.mktmpdir do |genout|
      run_genstrings(files: files, output_dir: genout)
      reference = Fastlane::Helper::Ios::L10nHelper.read_strings_file_as_hash(path: File.join(genout, 'Localizable.strings')).keys
      catalog_keys = JSON.parse(File.read(LOCALIZABLE_CATALOG))['strings'].keys
      gap = CatalogHelper.coverage_gap(reference, catalog_keys)

      if gap.empty?
        UI.success("Localizable.xcstrings covers all #{reference.count} genstrings keys. ✅")
      else
        gap.sort.first(25).each { |key| UI.error("  MISSING from catalog: #{key.inspect}") }
        UI.user_error!("#{gap.count} string(s) found by genstrings are missing from Localizable.xcstrings.")
      end
    end
  end

  #################################################
  # Helpers
  #################################################

  # Runs the legacy genstrings extraction (the verification reference) over the same files into output_dir.
  def run_genstrings(files:, output_dir:)
    sh('genstrings', '-s', CATALOG_LOCALIZATION_ROUTINE, '-o', output_dir, *files)
  end

  # Enumerate .swift/.m source files under the given roots, applying the same exclusions as the legacy lane:
  # vendored code, the unit-test harness, and AppLocalizedString.swift itself (its definition would otherwise
  # be misparsed as a call site).
  def catalog_source_files(roots)
    roots.flat_map { |root| Dir.glob(File.join(root, '**', '*.{swift,m}')) }
         .reject { |path| catalog_excluded?(path) }
         .uniq
         .sort
  end

  def catalog_excluded?(path)
    path.include?('Vendor/') ||
      path.include?('/WordPressTest/') ||
      File.basename(path) == 'AppLocalizedString.swift'
  end

  # xcstringstool extract -> one .stringsdata per source file (basename-disambiguated). Chunked to stay under
  # the OS argument limit; each chunk gets its own output subdir (see below), which sync then consumes together.
  # `--SwiftUI-Text` (extract `Text("literal")`) is OFF by default and gated behind `swiftui:`. The app has
  # ~91 such literals but only 16 `Text(verbatim:)`, so non-translatable glyphs (`Text("Aa")`, `Text("A")`)
  # are NOT guarded — extracting them would feed garbage to translators. Enabling it is a deliberate coverage
  # expansion that needs a cleanup pass first (convert non-translatable literals to `verbatim:`); then pass
  # `swiftui: true`.
  def extract_stringsdata(files:, output_dir:, swiftui: false)
    flags = [
      '--legacy-localizable-strings',     # NSLocalizedString + ObjC siblings
      '--modern-localizable-strings',     # String(localized:) / LocalizedStringResource — future catalog-native code
      '-s', CATALOG_LOCALIZATION_ROUTINE  # the app's AppLocalizedString custom routine
    ]
    flags << '--SwiftUI-Text' if swiftui
    # Chunk to stay under ARG_MAX, but give each chunk its OWN output dir. `extract` names .stringsdata by
    # source basename and only disambiguates collisions WITHIN a single invocation — so two same-named files
    # in different chunks (e.g. the two NSDate+Helpers.swift / SupportDataProvider.swift) would otherwise
    # overwrite each other in a shared dir and silently drop strings.
    files.each_slice(400).with_index do |chunk, index|
      chunk_dir = File.join(output_dir, "chunk-#{index}")
      FileUtils.mkdir_p(chunk_dir)
      sh('xcrun', 'xcstringstool', 'extract', *chunk, *flags, '--output-directory', chunk_dir)
    end
  end

  # All .stringsdata under a dir (recursive, since extract writes one subdir per chunk).
  def stringsdata_files(dir)
    Dir.glob(File.join(dir, '**', '*.stringsdata'))
  end

  # sync all the .stringsdata into Localizable.xcstrings. The catalog FILENAME selects the table, so this only
  # pulls in the `Localizable` table; strings routed to other tables (AppLocalizedString tableName:) are
  # ignored here and would sync into their own `<Table>.xcstrings`. Returns the resulting key count.
  def sync_localizable_catalog(stringsdata_dir:)
    ensure_catalog_exists(LOCALIZABLE_CATALOG)
    stringsdata = stringsdata_files(stringsdata_dir)
    UI.user_error!('xcstringstool produced no .stringsdata') if stringsdata.empty?

    sh('xcrun', 'xcstringstool', 'sync', LOCALIZABLE_CATALOG, *stringsdata.flat_map { |f| ['--stringsdata', f] })
    JSON.parse(File.read(LOCALIZABLE_CATALOG))['strings'].count
  end

  # Create the catalog as an empty shell if it doesn't exist yet; leave an existing one untouched so its
  # translations survive across runs — that persistence is what makes reconcile_changed_sources meaningful.
  def ensure_catalog_exists(path)
    FileUtils.mkdir_p(File.dirname(path))
    return if File.exist?(path)

    File.write(path, "#{JSON.pretty_generate('sourceLanguage' => 'en', 'strings' => {}, 'version' => '1.0')}\n")
  end

  # `xcstringstool sync` leaves an existing key's English value (and its translations) untouched when the
  # source text changes (verified). Re-derive the current English from a fresh extraction and, where it
  # differs from the catalog, update the English and flip that key's translations to `needs_review`.
  def reconcile_changed_sources(stringsdata_dir:)
    current_en = current_english_values(stringsdata_dir)
    catalog = JSON.parse(File.read(LOCALIZABLE_CATALOG))
    reconciled = CatalogHelper.reconcile_source_changes!(catalog, current_en)
    unless reconciled.empty?
      File.write(LOCALIZABLE_CATALOG, "#{JSON.pretty_generate(catalog)}\n")
      UI.important("Re-flagged #{reconciled.count} key(s) as needs_review — English source changed.")
    end
    reconciled.count
  end

  # Current English value per key, by syncing the extraction into a throwaway empty catalog (every key is
  # 'new', so its English is populated straight from source — which is what `sync` won't do for keys that
  # already exist in the real catalog).
  def current_english_values(stringsdata_dir)
    Dir.mktmpdir do |tmp|
      fresh = File.join(tmp, 'Localizable.xcstrings')
      File.write(fresh, "#{JSON.pretty_generate('sourceLanguage' => 'en', 'strings' => {}, 'version' => '1.0')}\n")
      stringsdata = stringsdata_files(stringsdata_dir)
      sh('xcrun', 'xcstringstool', 'sync', fresh, *stringsdata.flat_map { |f| ['--stringsdata', f] })
      english_values(JSON.parse(File.read(fresh)))
    end
  end

  # { key => English value } for every catalog entry that has one (skips key-as-source entries).
  def english_values(catalog)
    catalog['strings'].each_with_object({}) do |(key, entry), acc|
      value = entry.dig('localizations', 'en', 'stringUnit', 'value')
      acc[key] = value unless value.nil?
    end
  end

  def report_catalog(path, extracted_count:, reconciled_count:)
    catalog = JSON.parse(File.read(path))
    with_value = catalog['strings'].count { |_, v| v.dig('localizations', 'en', 'stringUnit', 'value') }
    message = "Generated #{File.basename(path)} with #{extracted_count} keys (#{with_value} carry an explicit English value; the rest are key-as-source)."
    message += " Re-flagged #{reconciled_count} for review (English source changed)." if reconciled_count.positive?
    UI.success(message)
  end
end
