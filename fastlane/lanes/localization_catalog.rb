# frozen_string_literal: true

require 'json'
require 'tmpdir'
require 'fileutils'
require 'open3'
require_relative 'catalog_helper'
require_relative 'catalog_strings_helper'

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
  File.join(PROJECT_ROOT_FOLDER, 'Modules', 'Sources'),
  File.join(PROJECT_ROOT_FOLDER, 'Sources')
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
      enforce_immutable_source_keys(stringsdata_dir: stringsdata_dir)
      report_catalog(LOCALIZABLE_CATALOG, extracted_count: synced)
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

  # LOCALIZE (download + fold + AI-fill) — pull the current GlotPress translations for the given locales and fold
  # them into the EXISTING Localizable.xcstrings (human => translated), then AI-fill the cells they leave empty
  # (=> needs_review). The download goes into a throwaway temp dir each run, so no stale or partial translation
  # state is ever carried between runs and the fold always reflects current GlotPress. Run generate_strings_catalog
  # (the code scan) first — it stays a separate lane so you can refresh the catalog without touching the AI. Scope
  # a cheap run with `locales:fr`; default is all ship locales.
  #
  # Uploading the AI drafts back to GlotPress as needs-review (the eventual "step 4") is a separate step, not
  # done here — it builds on the existing GlotPress import integration (cf. gp_update_metadata_source).
  #
  # STAGED, NOT SHIPPED: Localizable.xcstrings isn't the runtime store yet (the app still ships
  # Localizable.strings), so this only pre-populates it for the cutover — it changes nothing users see.
  #
  # MANUAL ONLY — not wired into download_localized_strings or any CI step: it downloads from GlotPress, calls the
  # translation API (cost), and commits a large catalog. Requires ANTHROPIC_API_KEY; keyless runs are refused.
  desc 'Download GlotPress translations + AI-fill into the existing Localizable.xcstrings (run generate_strings_catalog first)'
  lane :localize_catalog do |options|
    # Abort a keyless run: with no AI tier every gap folds to an English placeholder, so the lane would commit a
    # dense, near-zero-value catalog. Fail fast instead of staging it. (fold_translations! stays nil-tolerant for
    # tests and a possible future human-only flag; only the lane is gated.)
    if ENV['ANTHROPIC_API_KEY'].to_s.empty?
      UI.user_error!(
        'localize_catalog requires ANTHROPIC_API_KEY (the AI fill tier). Without it every gap folds to an ' \
        'English placeholder and the lane commits a dense, near-zero-value catalog. Run generate_strings_catalog ' \
        'for English-only extraction instead.'
      )
    end
    UI.user_error!("#{LOCALIZABLE_CATALOG} not found — run generate_strings_catalog first") unless File.exist?(LOCALIZABLE_CATALOG)
    locales = catalog_target_locales(options[:locales])

    # Download the current GlotPress translations (throwaway dir — no state carried between runs), fold them in
    # (=> translated), then AI-fill the cells they leave empty.
    catalog = JSON.parse(File.read(LOCALIZABLE_CATALOG))
    translations = download_catalog_translations(locales)
    UI.important('GlotPress returned no translations for the requested locale(s) — folding AI + English only.') if translations.empty?
    written = CatalogStrings.fold_translations!(
      catalog,
      translations_by_locale: translations,
      locales: locales.values.uniq,
      ai_translator: catalog_ai_translator
    )
    File.write(LOCALIZABLE_CATALOG, "#{JSON.pretty_generate(catalog)}\n")
    UI.success("Built #{File.basename(LOCALIZABLE_CATALOG)}: folded #{written} cell(s) across #{locales.values.uniq.size} locale(s).")
    report_localized_catalog(catalog, locales.values.uniq)

    # force: the catalog is .gitignore'd (shelved until the runtime cutover), so a plain `git add` refuses it —
    # this staging lane deliberately commits it anyway. Once tracked, the ignore no longer applies.
    git_add(path: LOCALIZABLE_CATALOG, shell_escape: false, force: true)
    git_commit(path: [LOCALIZABLE_CATALOG], message: 'Update Localizable.xcstrings translations (staged)', allow_nothing_to_commit: true)
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

  # Run `xcstringstool <args>` quietly via argv (no shell, so source paths with spaces are safe), capturing
  # output and surfacing it only on failure. Used instead of fastlane's `sh` for these bulk calls: each passes
  # hundreds of file paths (or a `--stringsdata` pair per file), so `sh` would echo a massive command line AND
  # print a "Step: shell command" banner per call. Open3 keeps the run silent and banner-free.
  def run_xcstringstool(*args)
    output, status = Open3.capture2e('xcrun', 'xcstringstool', *args)
    UI.user_error!("xcstringstool #{args.first} failed:\n#{output}") unless status.success?
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
    batches = files.each_slice(400).to_a
    batches.each_with_index do |chunk, index|
      chunk_dir = File.join(output_dir, "chunk-#{index}")
      FileUtils.mkdir_p(chunk_dir)
      UI.message("Extracting strings… (batch #{index + 1}/#{batches.size})")
      run_xcstringstool('extract', *chunk, *flags, '--output-directory', chunk_dir)
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

    UI.message("Syncing #{stringsdata.count} extracted file(s) into #{File.basename(LOCALIZABLE_CATALOG)}…")
    run_xcstringstool('sync', LOCALIZABLE_CATALOG, *stringsdata.flat_map { |f| ['--stringsdata', f] })
    JSON.parse(File.read(LOCALIZABLE_CATALOG))['strings'].count
  end

  # Create the catalog as an empty shell if it doesn't exist yet; leave an existing one untouched so its
  # translations survive across runs — that persistence is what lets the fold reuse machine cells and lets
  # immutable-key enforcement compare the source against the previously-stored English.
  def ensure_catalog_exists(path)
    FileUtils.mkdir_p(File.dirname(path))
    return if File.exist?(path)

    File.write(path, "#{JSON.pretty_generate('sourceLanguage' => 'en', 'strings' => {}, 'version' => '1.0')}\n")
  end

  # Localization keys are IMMUTABLE. `xcstringstool sync` silently keeps an existing key's translations when its
  # English is reworded in place (verified) — which would ship stale translations of the OLD text — so any
  # reworded (explicit-key) string is a hard error here: rewording requires a NEW key. Key-as-source strings are
  # exempt (rewording one changes the key, which sync handles as new/stale). See CatalogHelper.reworded_keys.
  def enforce_immutable_source_keys(stringsdata_dir:)
    current_en = current_english_values(stringsdata_dir)
    catalog = JSON.parse(File.read(LOCALIZABLE_CATALOG))
    reworded = CatalogHelper.reworded_keys(catalog, current_en)
    return if reworded.empty?

    UI.user_error!(
      "Localization keys are immutable, but #{reworded.count} changed their English in place: #{reworded.join(', ')}. " \
      "Rewording requires a new key (rename it) so translations don't go stale — mint a new key for the new text, " \
      'or revert the English change.'
    )
  end

  # Current English value per key, by syncing the extraction into a throwaway empty catalog (every key is
  # 'new', so its English is populated straight from source — which is what `sync` won't do for keys that
  # already exist in the real catalog).
  def current_english_values(stringsdata_dir)
    Dir.mktmpdir do |tmp|
      fresh = File.join(tmp, 'Localizable.xcstrings')
      File.write(fresh, "#{JSON.pretty_generate('sourceLanguage' => 'en', 'strings' => {}, 'version' => '1.0')}\n")
      stringsdata = stringsdata_files(stringsdata_dir)
      run_xcstringstool('sync', fresh, *stringsdata.flat_map { |f| ['--stringsdata', f] })
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

  def report_catalog(path, extracted_count:)
    catalog = JSON.parse(File.read(path))
    with_value = catalog['strings'].count { |_, v| v.dig('localizations', 'en', 'stringUnit', 'value') }
    UI.success("Generated #{File.basename(path)} with #{extracted_count} keys (#{with_value} carry an explicit English value; the rest are key-as-source).")
  end

  # Print a per-locale summary of the fold so a run can be eyeballed straight from the log (see
  # CatalogStrings.summarize / .summary_lines for the counts and sample formatting).
  def report_localized_catalog(catalog, locales)
    CatalogStrings.summary_lines(CatalogStrings.summarize(catalog, locales: locales)).each { |line| UI.message(line) }
  end

  # The { glotpress => lproj } locale map to operate on: all ship locales, or the subset named in `locales:`
  # (a comma-separated list of lproj codes, e.g. `locales:fr,de`) for a cheap scoped run. Resolution is pure
  # (CatalogStrings.select_locales); the lane only turns its result into user-facing errors/warnings.
  def catalog_target_locales(spec)
    selected, unknown = CatalogStrings.select_locales(spec, GLOTPRESS_TO_LPROJ_APP_LOCALE_CODES).values_at(:selected, :unknown)
    UI.user_error!("No known ship locales among #{spec.inspect} (use lproj codes, e.g. fr,de,pt-BR)") if selected.empty?
    UI.important("Ignoring unrecognized locale(s): #{unknown.join(', ')} (use lproj codes, e.g. fr,de,pt-BR)") unless unknown.empty?
    selected
  end

  # Download the current GlotPress translations for `locales` ({ glotpress => lproj }) into a throwaway dir and
  # return them as { lproj => { key => human value } } for the fold. A fresh temp dir per run means no stale or
  # partial translation state is ever carried between runs — the fold always reflects current GlotPress, and its
  # scope can't silently diverge from what's folded. Never touches the tracked `WordPress/Resources/*.lproj` tree
  # (download_localized_strings owns the shipping `.strings`); the catalog flow only consumes translations.
  def download_catalog_translations(locales)
    Dir.mktmpdir do |dir|
      ios_download_strings_files_from_glotpress(
        project_url: GLOTPRESS_APP_STRINGS_PROJECT_URL,
        locales: locales,
        download_dir: dir
      )
      catalog_translations_by_locale(dir)
    end
  end

  # { lproj => { key => human value } } from the downloaded translation `.strings`. The flat plural keys present
  # in these files aren't catalog keys, so the fold ignores them (they belong to Plurals.xcstrings).
  def catalog_translations_by_locale(dir)
    Dir.glob(File.join(dir, '*.lproj', 'Localizable.strings')).each_with_object({}) do |path, acc|
      locale = File.basename(File.dirname(path), '.lproj')
      acc[locale] = Fastlane::Helper::Ios::L10nHelper.read_strings_file_as_hash(path: path)
    end
  end

  # The AI tier for the catalog fold, or nil when ANTHROPIC_API_KEY isn't set (the fold then fills only human +
  # English). Returns `call(entries, locale) => { key => translation }` via AITranslator#translate_all.
  #
  # Wrapped to DEGRADE, not crash — three non-fatal paths. A batch failing mid-locale is handled inside
  # translate_all: it keeps the batches that already succeeded, warns to stderr, and returns the partial result
  # (the unfilled cells fall back to English and retry next run), so the fold still proceeds and commits. The
  # lambda's own rescue is only a backstop for anything that escapes translate_all (e.g. a failure before the
  # batch loop starts) — it logs and returns {}, dropping that whole locale to English. A setup error — the gem
  # missing (LoadError) or the client failing to construct (any StandardError, e.g. a malformed
  # ANTHROPIC_BASE_URL) — logs and returns nil, disabling the AI tier for this run while the human/English fold
  # still proceeds and commits (rather than dropping the whole localize_catalog lane).
  def catalog_ai_translator
    if ENV['ANTHROPIC_API_KEY'].to_s.empty?
      UI.important('ANTHROPIC_API_KEY not set — folding human + English only; undefined cells stay English (needs_review).')
      return nil
    end

    require_relative 'ai_translator'
    translator = AITranslator.with_anthropic
    lambda do |entries, locale|
      translator.translate_all(entries, locale: locale)
    rescue StandardError => e
      UI.error("AI catalog translation failed for #{locale} (#{e.message}); leaving its undefined cells to English.")
      {}
    end
  rescue LoadError, StandardError => e
    UI.important("AI translation tier unavailable (#{e.message}); folding human + English only.")
    nil
  end
end
