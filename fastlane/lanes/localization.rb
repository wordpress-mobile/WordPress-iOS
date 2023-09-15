# frozen_string_literal: true

#################################################
# Constants
#################################################

# URL of the GlotPress project containing the app's strings
GLOTPRESS_APP_STRINGS_PROJECT_URL = 'https://translate.wordpress.org/projects/apps/ios/dev/'

# URL of the GlotPress projects containing App Store metadata (title, keywords, release notes, …)
GLOTPRESS_WORDPRESS_APP_STORE_METADATA_PROJECT_URL = 'https://translate.wordpress.org/projects/apps/ios/release-notes/'
GLOTPRESS_JETPACK_APP_STORE_METADATA_PROJECT_URL = 'https://translate.wordpress.com/projects/jetpack/apps/ios/release-notes/'

# List of locales used for the app strings (GlotPress code => `*.lproj` folder name`)
#
# TODO: Replace with `LocaleHelper` once provided by release toolkit (https://github.com/wordpress-mobile/release-toolkit/pull/296)
GLOTPRESS_TO_LPROJ_APP_LOCALE_CODES = {
  'ar' => 'ar',         # Arabic
  'bg' => 'bg',         # Bulgarian
  'cs' => 'cs',         # Czech
  'cy' => 'cy',         # Welsh
  'da' => 'da',         # Danish
  'de' => 'de',         # German
  'en-au' => 'en-AU',   # English (Australia)
  'en-ca' => 'en-CA',   # English (Canada)
  'en-gb' => 'en-GB',   # English (UK)
  'es' => 'es',         # Spanish
  'fr' => 'fr',         # French
  'he' => 'he',         # Hebrew
  'hr' => 'hr',         # Croatian
  'hu' => 'hu',         # Hungarian
  'id' => 'id',         # Indonesian
  'is' => 'is',         # Icelandic
  'it' => 'it',         # Italian
  'ja' => 'ja',         # Japanese
  'ko' => 'ko',         # Korean
  'nb' => 'nb',         # Norwegian (Bokmål)
  'nl' => 'nl',         # Dutch
  'pl' => 'pl',         # Polish
  'pt' => 'pt',         # Portuguese
  'pt-br' => 'pt-BR',   # Portuguese (Brazil)
  'ro' => 'ro',         # Romainian
  'ru' => 'ru',         # Russian
  'sk' => 'sk',         # Slovak
  'sq' => 'sq',         # Albanian
  'sv' => 'sv',         # Swedish
  'th' => 'th',         # Thai
  'tr' => 'tr',         # Turkish
  'zh-cn' => 'zh-Hans', # Chinese (China)
  'zh-tw' => 'zh-Hant'  # Chinese (Taiwan)
}.freeze

# Mapping of all locales which can be used for AppStore metadata (Glotpress code => AppStore Connect code)
#
# TODO: Replace with `LocaleHelper` once provided by release toolkit (https://github.com/wordpress-mobile/release-toolkit/pull/296)
GLOTPRESS_TO_ASC_METADATA_LOCALE_CODES = {
  'ar' => 'ar-SA',
  'da' => 'da',
  'de' => 'de-DE',
  'en-au' => 'en-AU',
  'en-ca' => 'en-CA',
  'en-gb' => 'en-GB',
  'es' => 'es-ES',
  'es-mx' => 'es-MX',
  'fr' => 'fr-FR',
  'he' => 'he',
  'id' => 'id',
  'it' => 'it',
  'ja' => 'ja',
  'ko' => 'ko',
  'nl' => 'nl-NL',
  'nb' => 'no',
  'pt-br' => 'pt-BR',
  'pt' => 'pt-PT',
  'ru' => 'ru',
  'sv' => 'sv',
  'th' => 'th',
  'tr' => 'tr',
  'zh-cn' => 'zh-Hans',
  'zh-tw' => 'zh-Hant'
}.freeze

# Locales used in AppStore for WordPress metadata
WORDPRESS_METADATA_GLOTPRESS_LOCALE_CODES = GLOTPRESS_TO_ASC_METADATA_LOCALE_CODES.keys.freeze # all of them
# Locales used in AppStore for Jetpack metadata
JETPACK_METADATA_GLOTPRESS_LOCALE_CODES = %w[ar de es fr he id it ja ko nl pt-br ru sv tr zh-cn zh-tw].freeze

# List of `.strings` files manually maintained by developers (as opposed to being automatically extracted from code and generated)
# which we will merge into the main `Localizable.strings` file imported by GlotPress, then extract back once we download the translations.
# Each `.strings` file to be merged/extracted is associated with a prefix to add to the keys, used to avoid conflicts and differentiate the source of the copies.
# See calls to `ios_merge_strings_files` and `ios_extract_keys_from_strings_files` for usage.
#
MANUALLY_MAINTAINED_STRINGS_FILES = {
  File.join('WordPress', 'Resources', 'en.lproj', 'InfoPlist.strings') => 'infoplist.', # For now WordPress and Jetpack share the same InfoPlist.strings
  File.join('WordPress', 'WordPressDraftActionExtension', 'en.lproj', 'InfoPlist.strings') => 'ios-sharesheet.', # CFBundleDisplayName for the "Save as Draft" share action
  File.join('WordPress', 'JetpackDraftActionExtension', 'en.lproj', 'InfoPlist.strings') => 'ios-jetpack-sharesheet.', # CFBundleDisplayName for the "Save to Jetpack" share action
  File.join('WordPress', 'JetpackIntents', 'en.lproj', 'Sites.strings') => 'ios-widget.' # Strings from the `.intentdefinition`, used for configuring the iOS Widget
}.freeze

# Application-agnostic settings for the `upload_to_app_store` action (also known as `deliver`).
# Used in `update_*_metadata_on_app_store_connect` lanes.
#
UPLOAD_TO_APP_STORE_COMMON_PARAMS = {
  app_version: get_app_version,
  skip_binary_upload: true,
  overwrite_screenshots: true,
  phased_release: true,
  precheck_include_in_app_purchases: false,
  api_key_path: APP_STORE_CONNECT_KEY_PATH,
  app_rating_config_path: File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'metadata', 'ratings_config.json')
}.freeze

#################################################
# Lanes
#################################################

# Lanes related to Localization and GlotPress
#
platform :ios do
  # Generates the `.strings` file to be imported by GlotPress, by parsing source code (using `genstrings` under the hood).
  #
  # @called_by complete_code_freeze
  #
  lane :generate_strings_file_for_glotpress do |options|
    cocoapods

    # On top of fetching the latest Pods, we also need to fetch the source for the Gutenberg code.
    # To get it, we need to manually clone the repo, since Gutenberg is distributed via XCFramework.
    # XCFrameworks are binary targets and cannot extract strings via genstrings from there.
    config = gutenberg_config!

    ref_node = config[:ref]
    UI.user_error!('Could not find Gutenberg ref to clone the repository in order to access its strings.') if ref_node.nil?

    ref = ref_node[:tag] || ref_node[:commit]
    UI.user_error!('The ref to clone Gutenberg in order to access its strings has neither tag nor commit values.') if ref.nil?

    github_org = config[:github_org]
    UI.user_error!('Could not find GitHub organization name to clone Gutenberg in order to access its strings.') if github_org.nil?

    repo_name = config[:repo_name]
    UI.user_error!('Could not find GitHub repository name to clone Gutenberg in order to access its strings.') if repo_name.nil?

    # Create a temporary directory to clone Gutenberg into.
    # We'll run the rest of the automation from within the block, but notice that only the Gutenbreg cloning happens within the temporary directory.
    gutenberg_clone_name = 'Gutenberg-Strings-Clone'
    Dir.mktmpdir do |tempdir|
      Dir.chdir(tempdir) do
        repo_url = "https://github.com/#{github_org}/#{repo_name}"
        UI.message("Cloning Gutenberg from #{repo_url} into #{gutenberg_clone_name}. This might take a few minutes…")
        sh("git clone --depth 1 #{repo_url} #{gutenberg_clone_name}")
        Dir.chdir(gutenberg_clone_name) do
          if config[:ref][:tag]
            sh("git fetch origin refs/tags/#{ref}:refs/tags/#{ref}")
            sh("git checkout refs/tags/#{ref}")
          else
            sh("git fetch origin #{ref}")
            sh("git checkout #{ref}")
          end
        end
      end

      # Notice that we are no longer in the tempdir, so the paths below are back to being relative to the project root folder.
      # However, we are still in the tempdir block, so that once the automation is done, the tempdir will be automatically deleted.
      wordpress_en_lproj = File.join('WordPress', 'Resources', 'en.lproj')
      ios_generate_strings_file_from_code(
        paths: ['WordPress/', 'Pods/WordPress*/', 'Pods/WPMediaPicker/', 'WordPressShared/WordPressShared/', File.join(tempdir, gutenberg_clone_name)],
        exclude: ['*Vendor*', 'WordPress/WordPressTest/**', '**/AppLocalizedString.swift'],
        routines: ['AppLocalizedString'],
        output_dir: wordpress_en_lproj
      )

      # Merge various manually-maintained `.strings` files into the previously generated `Localizable.strings` so their extra keys are also imported in GlotPress.
      # Note: We will re-extract the translations back during `download_localized_strings_and_metadata` (via a call to `ios_extract_keys_from_strings_files`)
      ios_merge_strings_files(
        paths_to_merge: MANUALLY_MAINTAINED_STRINGS_FILES,
        destination: File.join(wordpress_en_lproj, 'Localizable.strings')
      )

      git_commit(path: [wordpress_en_lproj], message: 'Update strings for localization', allow_nothing_to_commit: true) unless options[:skip_commit]
    end
  end

  # Updates the `AppStoreStrings.po` files (WP+JP) with the latest content from the `release_notes.txt` files and the other text sources
  #
  # @option [String] version The current `x.y` version of the app. Optional. Used to derive the `release_notes_xxy` key to use in the `.po` file.
  #
  desc 'Updates the AppStoreStrings.po file with the latest data'
  lane :update_appstore_strings do |options|
    update_wordpress_appstore_strings(options)
    update_jetpack_appstore_strings(options)
  end

  # Updates the `AppStoreStrings.po` file for WordPress, with the latest content from the `release_notes.txt` file and the other text sources
  #
  # @option [String] version The current `x.y` version of the app. Optional. Used to derive the `release_notes_xxy` key to use in the `.po` file.
  #
  desc 'Updates the AppStoreStrings.po file for the WordPress app with the latest data'
  lane :update_wordpress_appstore_strings do |options|
    source_metadata_folder = File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'metadata', 'default')
    custom_metadata_folder = File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'appstoreres', 'metadata', 'source')
    version = options.fetch(:version, get_app_version)

    files = {
      whats_new: WORDPRESS_RELEASE_NOTES_PATH,
      app_store_name: File.join(source_metadata_folder, 'name.txt'),
      app_store_subtitle: File.join(source_metadata_folder, 'subtitle.txt'),
      app_store_desc: File.join(source_metadata_folder, 'description.txt'),
      app_store_keywords: File.join(source_metadata_folder, 'keywords.txt'),
      'standard-whats-new-1' => File.join(custom_metadata_folder, 'standard_whats_new_1.txt'),
      'standard-whats-new-2' => File.join(custom_metadata_folder, 'standard_whats_new_2.txt'),
      'standard-whats-new-3' => File.join(custom_metadata_folder, 'standard_whats_new_3.txt'),
      'standard-whats-new-4' => File.join(custom_metadata_folder, 'standard_whats_new_4.txt'),
      'app_store_screenshot-1' => File.join(custom_metadata_folder, 'promo_screenshot_1.txt'),
      'app_store_screenshot-2' => File.join(custom_metadata_folder, 'promo_screenshot_2.txt'),
      'app_store_screenshot-3' => File.join(custom_metadata_folder, 'promo_screenshot_3.txt'),
      'app_store_screenshot-4' => File.join(custom_metadata_folder, 'promo_screenshot_4.txt'),
      'app_store_screenshot-5' => File.join(custom_metadata_folder, 'promo_screenshot_5.txt'),
      'app_store_screenshot-6' => File.join(custom_metadata_folder, 'promo_screenshot_6.txt'),
      'app_store_screenshot-7' => File.join(custom_metadata_folder, 'promo_screenshot_7.txt')
    }

    ios_update_metadata_source(
      po_file_path: File.join(PROJECT_ROOT_FOLDER, 'WordPress', 'Resources', 'AppStoreStrings.po'),
      source_files: files,
      release_version: version
    )
  end

  # Updates the `AppStoreStrings.po` file for Jetpack, with the latest content from the `release_notes.txt` file and the other text sources
  #
  # @option [String] version The current `x.y` version of the app. Optional. Used to derive the `release_notes_xxy` key to use in the `.po` file.
  #
  desc 'Updates the AppStoreStrings.po file for the Jetpack app with the latest data'
  lane :update_jetpack_appstore_strings do |options|
    source_metadata_folder = File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'jetpack_metadata', 'default')
    custom_metadata_folder = File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'appstoreres', 'jetpack_metadata', 'source')
    version = options.fetch(:version, get_app_version)

    files = {
      whats_new: JETPACK_RELEASE_NOTES_PATH,
      app_store_name: File.join(source_metadata_folder, 'name.txt'),
      app_store_subtitle: File.join(source_metadata_folder, 'subtitle.txt'),
      app_store_desc: File.join(source_metadata_folder, 'description.txt'),
      app_store_keywords: File.join(source_metadata_folder, 'keywords.txt'),
      'screenshot-text-1' => File.join(custom_metadata_folder, 'promo_screenshot_1.txt'),
      'screenshot-text-2' => File.join(custom_metadata_folder, 'promo_screenshot_2.txt'),
      'screenshot-text-3' => File.join(custom_metadata_folder, 'promo_screenshot_3.txt'),
      'screenshot-text-4' => File.join(custom_metadata_folder, 'promo_screenshot_4.txt'),
      'screenshot-text-5' => File.join(custom_metadata_folder, 'promo_screenshot_5.txt'),
      'screenshot-text-6' => File.join(custom_metadata_folder, 'promo_screenshot_6.txt')
    }

    ios_update_metadata_source(
      po_file_path: File.join(PROJECT_ROOT_FOLDER, 'WordPress', 'Jetpack', 'Resources', 'AppStoreStrings.po'),
      source_files: files,
      release_version: version
    )
  end


  # Downloads the localized app strings and App Store Connect metadata from GlotPress.
  #
  desc 'Downloads localized metadata for App Store Connect from GlotPress'
  lane :download_localized_strings_and_metadata do
    # Download `Localizable.strings` translations used within the app
    parent_dir_for_lprojs = File.join(PROJECT_ROOT_FOLDER, 'WordPress', 'Resources')
    ios_download_strings_files_from_glotpress(
      project_url: GLOTPRESS_APP_STRINGS_PROJECT_URL,
      locales: GLOTPRESS_TO_LPROJ_APP_LOCALE_CODES,
      download_dir: parent_dir_for_lprojs
    )
    git_commit(
      path: File.join(parent_dir_for_lprojs, '*.lproj', 'Localizable.strings'),
      message: 'Update app translations – `Localizable.strings`',
      allow_nothing_to_commit: true
    )

    # Redispatch the appropriate subset of translations back to the manually-maintained `.strings`
    # files that we previously merged via `ios_merge_strings_files` during `complete_code_freeze`
    modified_files = ios_extract_keys_from_strings_files(
      source_parent_dir: parent_dir_for_lprojs,
      target_original_files: MANUALLY_MAINTAINED_STRINGS_FILES
    )
    # Manually add files in case there are entirely new localization files.
    # Fastlane's `git_commit` can only commit changes to existing files.
    git_add(path: modified_files, shell_escape: false)
    git_commit(
      path: modified_files,
      message: 'Update app translations – Other `.strings`',
      allow_nothing_to_commit: true
    )

    # Finally, also download the AppStore metadata (app title, keywords, etc.)
    download_wordpress_localized_app_store_metadata
    download_jetpack_localized_app_store_metadata
  end

  # Downloads the localized metadata (for App Store Connect) from GlotPress for the WordPress app.
  #
  desc 'Downloads the localized metadata (for App Store Connect) from GlotPress for the WordPress app'
  lane :download_wordpress_localized_app_store_metadata do
    metadata_directory = File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'metadata')

    # FIXME: We should make the `fastlane/metadata/default/release_notes.txt` path be the source of truth for the original copies in the future.
    # (will require changes in the `update_appstore_strings` lane, the Release Scenario, the MC tool to generate the announcement post…)
    #
    # In the meantime, just copy the file to the right place for `deliver` to find, for the `default` pseudo-locale which is used as fallback
    release_notes_source = WORDPRESS_RELEASE_NOTES_PATH
    FileUtils.cp(release_notes_source, File.join(metadata_directory, 'default', 'release_notes.txt'))

    # Download metadata translations from GlotPress
    download_localized_app_store_metadata(
      glotpress_project_url: GLOTPRESS_WORDPRESS_APP_STORE_METADATA_PROJECT_URL,
      metadata_directory:,
      locales: WORDPRESS_METADATA_GLOTPRESS_LOCALE_CODES,
      commit_message: 'Update WordPress metadata translations'
    )
  end

  # Downloads the localized metadata (for App Store Connect) from GlotPress for the Jetpack app
  #
  desc 'Downloads the localized metadata (for App Store Connect) from GlotPress for the Jetpack app'
  lane :download_jetpack_localized_app_store_metadata do
    metadata_directory = File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'jetpack_metadata')

    # FIXME: We should make the `fastlane/jetpack_metadata/default/release_notes.txt` path be the source of truth for the original copies in the future.
    # (will require changes in the `update_appstore_strings` lane, the Release Scenario, the MC tool to generate the announcement post…)
    #
    # In the meantime, just copy the file to the right place for `deliver` to find, for the `default` pseudo-locale which is used as fallback
    release_notes_source = JETPACK_RELEASE_NOTES_PATH
    FileUtils.cp(release_notes_source, File.join(metadata_directory, 'default', 'release_notes.txt'))

    # Download metadata translations from GlotPress
    download_localized_app_store_metadata(
      glotpress_project_url: GLOTPRESS_JETPACK_APP_STORE_METADATA_PROJECT_URL,
      locales: JETPACK_METADATA_GLOTPRESS_LOCALE_CODES,
      metadata_directory:,
      commit_message: 'Update Jetpack metadata translations'
    )
  end

  # rubocop:disable Metrics/AbcSize
  #
  # Reference: http://wiki.c2.com/?AbcMetric
  def download_localized_app_store_metadata(glotpress_project_url:, locales:, metadata_directory:, commit_message:)
    # FIXME: Replace this with a call to the future replacement of `gp_downloadmetadata` once it's implemented in the release-toolkit (see paaHJt-31O-p2).

    locales_map = GLOTPRESS_TO_ASC_METADATA_LOCALE_CODES.slice(*locales)
    target_files = {
      "v#{get_app_version}-whats-new": { desc: 'release_notes.txt', max_size: 4000 },
      app_store_name: { desc: 'name.txt', max_size: 30 },
      app_store_subtitle: { desc: 'subtitle.txt', max_size: 30 },
      app_store_desc: { desc: 'description.txt', max_size: 4000 },
      app_store_keywords: { desc: 'keywords.txt', max_size: 100 }
    }

    gp_downloadmetadata(
      project_url: glotpress_project_url,
      target_files:,
      locales: locales_map,
      download_path: metadata_directory
    )
    files_to_commit = [File.join(metadata_directory, '**', '*.txt')]

    # Ensure that none of the `.txt` files in `en-US` would accidentally override our originals in `default`
    target_files.values.map { |h| h[:desc] }.each do |file|
      en_file_path = File.join(metadata_directory, 'en-US', file)
      if File.exist?(en_file_path)
        UI.user_error!("File `#{en_file_path}` would override the same one in `#{metadata_directory}/default`, but `default/` is the source of truth. " \
          + "Delete the `#{en_file_path}` file, ensure the `default/` one has the expected original copy, and try again.")
      end
    end

    # Ensure even empty locale folders have an empty `.gitkeep` file (in case we don't have any translation at all ready for some locales)
    locales_map.each_value do |locale|
      gitkeep = File.join(metadata_directory, locale, '.gitkeep')
      next if File.exist?(gitkeep)

      FileUtils.mkdir_p(File.dirname(gitkeep))
      FileUtils.touch(gitkeep)
      files_to_commit.append(gitkeep)
    end

    # Commit
    git_add(path: files_to_commit, shell_escape: false)
    git_commit(
      path: files_to_commit,
      message: commit_message,
      allow_nothing_to_commit: true
    )
  end
  # rubocop:enable Metrics/AbcSize

  # Uploads the localized metadata for WordPress and Jetpack (from `fastlane/{metadata,jetpack_metadata}/`) to App Store Connect
  #
  # @option [Boolean] with_screenshots (default: false) If true, will also upload the latest screenshot files to ASC
  #
  desc 'Updates the App Store Connect localized metadata'
  lane :update_metadata_on_app_store_connect do |options|
    update_wordpress_metadata_on_app_store_connect(options)
    update_jetpack_metadata_on_app_store_connect(options)
  end

  # Uploads the localized metadata for WordPress (from `fastlane/metadata/`) to App Store Connect
  #
  # @option [Boolean] with_screenshots (default: false) If true, will also upload the latest screenshot files to ASC
  #
  desc 'Uploads the WordPress metadata to App Store Connect, localized, and optionally including screenshots.'
  lane :update_wordpress_metadata_on_app_store_connect do |options|
    # Skip screenshots by default. The naming is "with" to make it clear that
    # callers need to opt-in to adding screenshots. The naming of the deliver
    # parameter, on the other hand, uses the skip verb.
    with_screenshots = options.fetch(:with_screenshots, false)
    skip_screenshots = with_screenshots == false

    upload_to_app_store(
      **UPLOAD_TO_APP_STORE_COMMON_PARAMS,
      app_identifier: WORDPRESS_BUNDLE_IDENTIFIER,
      screenshots_path: File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'promo-screenshots'),
      skip_screenshots:
    )
  end

  # Uploads the localized metadata for Jetpack (from `fastlane/jetpack_metadata/`) to App Store Connect
  #
  # @option [Boolean] with_screenshots (default: false) If true, will also upload the latest screenshot files to ASC
  #
  desc 'Uploads the Jetpack metadata to App Store Connect, localized, and optionally including screenshots.'
  lane :update_jetpack_metadata_on_app_store_connect do |options|
    # Skip screenshots by default. The naming is "with" to make it clear that
    # callers need to opt-in to adding screenshots. The naming of the deliver
    # parameter, on the other hand, uses the skip verb.
    with_screenshots = options.fetch(:with_screenshots, false)
    skip_screenshots = with_screenshots == false

    upload_to_app_store(
      **UPLOAD_TO_APP_STORE_COMMON_PARAMS,
      app_identifier: JETPACK_BUNDLE_IDENTIFIER,
      metadata_path: File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'jetpack_metadata'),
      screenshots_path: File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'jetpack_promo_screenshots'),
      skip_screenshots:
    )
  end


  # Checks the translation progress (%) of all Mag16 for all the projects (app strings and metadata) in GlotPress.
  #
  # @option [Boolean] interactive (default: false) If true, will pause and ask confirmation to continue if it found any locale translated below the threshold
  #
  desc 'Check translation progress for all GlotPress projects'
  lane :check_all_translations do |options|
    abort_on_violations = false
    skip_confirm = options.fetch(:interactive, false) == false

    UI.message('Checking app strings translation status...')
    check_translation_progress(
      glotpress_url: GLOTPRESS_APP_STRINGS_PROJECT_URL,
      abort_on_violations:,
      skip_confirm:
    )

    UI.message('Checking WordPress release notes strings translation status...')
    check_translation_progress(
      glotpress_url: GLOTPRESS_WORDPRESS_APP_STORE_METADATA_PROJECT_URL,
      abort_on_violations:,
      skip_confirm:
    )

    UI.message('Checking Jetpack release notes strings translation status...')
    check_translation_progress(
      glotpress_url: GLOTPRESS_JETPACK_APP_STORE_METADATA_PROJECT_URL,
      abort_on_violations:,
      skip_confirm:
    )
  end
end
