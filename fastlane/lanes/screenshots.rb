# frozen_string_literal: true

require 'fileutils'

# Be sure to keep the `fastlane/screenshots.json` and `fastlane/jetpack_screenshots.json` files in sync with that list as well
#
# Screen Sizes Reference Charts:
# - https://size-charts.com/topics/screen-size-charts/apple-iphone-size/
# - https://size-charts.com/topics/screen-size-charts/apple-ipad-size-chart/
#
SCREENSHOT_SIMULATORS = [
  'iPhone Xs Max', # 6.5in - 2688x1242 @ 458 ppi
  'iPhone 8 Plus', # 5.5in - 1920x1080 @ 401 ppi -- !!! FIXME: `canvas_size` in `fastlane/screenshots.json` does not match ([1242, 2208])
  'iPad Pro (12.9-inch) (2nd generation)', # 12.9in - 2732x2048 @ 264 ppi
  'iPad Pro (12.9-inch) (5th generation)' # 12.9in - 2732x2048 @ 264 ppi
].freeze

#################################################
# Lanes
#################################################

# Lanes related to Generating Screenshots
#
platform :ios do
  # Generates the localized raw screenshots (for WordPress by default), using the dedicated UI test scheme
  #
  # Generates both light and dark mode, for each locale, and a fixed set of device sizes (2 iPhones, 2 iPads)
  #
  # @option [String] scheme (default: "WordPressScreenshotGeneration") The name of the scheme to use to run the screenshots
  # @option [String] output_directory (default: `${PWD}/screenhots`) The directory to generate the screenshots to
  # @option [Array<String>] language (default: the list of Mag16 locales) The subset of locales to generate the screenshots for
  # @option [Boolean] skip_clean Skip the deletion of DerivedData before starting. Useful to speed up iterating while adjusting screenshots until we're happy with the final results, for example
  #
  # @note When you're working on updating the screenshots with new design, and might need to run this lane multiple time to do some
  # trial and errors to adjust the results until you're happy with it, you might want to run this lane with the following options:
  #
  #   `bundle exec fastlane screenshots language:fr-FR skip_clean:true`
  #
  # That way, it uses incremental builds instead of clean builds (faster iterations), and only generates screenshots for one language
  # (which is usually enough to check that the design and screens being captured look correct while iterating).
  #
  desc 'Generate localised screenshots'
  lane :screenshots do |options|
    cocoapods # pod install

    FileUtils.rm_rf(DERIVED_DATA_PATH) unless options[:skip_clean]

    scheme = options[:scheme] || 'WordPressScreenshotGeneration'

    output_directory = options[:output_directory] || File.join(Dir.pwd, '/screenshots')

    scan(
      workspace: WORKSPACE_PATH,
      scheme:,
      build_for_testing: true,
      derived_data_path: DERIVED_DATA_PATH
    )

    languages = %w[ar-SA da de-DE en-AU en-CA en-GB es-ES fr-FR he id it ja ko no nl-NL pt-BR pt-PT ru sv th tr zh-Hans zh-Hant en-US]

    # Allow creating screenshots for just one languages
    unless options[:language].nil?
      languages.keep_if do |language|
        language.casecmp(options[:language]).zero?
      end
    end

    dark_mode_values = options[:skip_dark_mode] ? [false] : [true, false]

    UI.message "--- Generating screenshots for the following languages: #{languages}"

    create_missing_simulators_for_screenshots
    dark_mode_values.each do |dark_mode_enabled|
      capture_ios_screenshots(
        workspace: WORKSPACE_PATH,
        scheme:,
        test_without_building: true,
        derived_data_path: DERIVED_DATA_PATH,
        output_directory:,
        languages:,
        dark_mode: dark_mode_enabled,
        override_status_bar: true,

        reinstall_app: true,
        erase_simulator: true,
        localize_simulator: true,
        concurrent_simulators: false,

        devices: SCREENSHOT_SIMULATORS
      )
    end
  end

  # Generates the localized raw screenshots for Jetpack, using the dedicated `JetpackScreenshotGeneration` UI test scheme
  #
  # Generates both light and dark mode, for each of the Mag16 locale, and a fixed set of device sizes (2 iPhones, 2 iPads).
  #
  desc 'Generate localised Jetpack screenshots'
  lane :jetpack_screenshots do |options|
    screenshots(
      scheme: 'JetpackScreenshotGeneration',
      output_directory: File.join(Dir.pwd, '/jetpack_screenshots'),
      language: options[:language],
      skip_clean: options[:skip_clean],
      skip_dark_mode: true
    )
  end

  # Generates the promo screenshots for WordPress from the raw screenshots and the `screenshots.json` assembly description file.
  #
  # @see https://github.com/wordpress-mobile/release-toolkit/blob/trunk/docs/screenshot-compositor.md for documentation
  #
  # - Raw screenshots are expected to be in the `screenshots/`
  # - Localized metadata for the screenshots are expected to be in `appstoreres/metadata`
  # - Generated promo screenshots will be generated in `fastlane//promo_screenshots`
  #
  desc 'Creates promo screenshots'
  lane :create_promo_screenshots do |options|
    # All file paths are relative to the `Fastfile`.
    promo_screenshots(
      orig_folder: 'screenshots',
      metadata_folder: 'appstoreres/metadata',
      output_folder: File.join(Dir.pwd, '/promo_screenshots'),
      force: options[:force]
    )
  end

  # Generates the promo screenshots for Jetpack from the raw screenshots and the `jetpack_screenshots.json` assembly description file.
  #
  # @see https://github.com/wordpress-mobile/release-toolkit/blob/trunk/docs/screenshot-compositor.md for documentation
  #
  # - Raw screenshots are expected to be in the `jetpack_screenshots/`
  # - Localized metadata for the screenshots are expected to be in `fastlane/appstoreres/jetpack_metadata`
  # - Generated promo screenshots will be generated in `fastlane/jetpack_promo_screenshots`
  #
  desc 'Creates Jetpack promo screenshots'
  lane :create_jetpack_promo_screenshots do |options|
    # All file paths are relative to the `Fastfile`.
    promo_screenshots(
      orig_folder: 'jetpack_screenshots',
      metadata_folder: 'appstoreres/jetpack_metadata',
      config_file: 'jetpack_screenshots.json',
      output_folder: File.join(Dir.pwd, '/jetpack_promo_screenshots'),
      force: options[:force]
    )
  end

  # Downloads the latest strings from GlotPress used for the creation of the WordPress promo screenshots.
  #
  # The downloaded strings will be save in `fastlane/appstoreres/metadata`
  #
  desc 'Downloads translated promo strings for WordPress from GlotPress'
  lane :download_promo_strings do
    files = {
      'app_store_screenshot-1' => { desc: 'app_store_screenshot_1.txt' },
      'app_store_screenshot-2' => { desc: 'app_store_screenshot_2.txt' },
      'app_store_screenshot-3' => { desc: 'app_store_screenshot_3.txt' },
      'app_store_screenshot-4' => { desc: 'app_store_screenshot_4.txt' },
      'app_store_screenshot-5' => { desc: 'app_store_screenshot_5.txt' },
      'app_store_screenshot-6' => { desc: 'app_store_screenshot_6.txt' },
      'app_store_screenshot-7' => { desc: 'app_store_screenshot_7.txt' },
      'app_store_screenshot-8' => { desc: 'app_store_screenshot_8.txt' },

      'enhanced_app_store_screenshot-1' => { desc: 'app_store_screenshot_1.html' },
      'enhanced_app_store_screenshot-2' => { desc: 'app_store_screenshot_2.html' },
      'enhanced_app_store_screenshot-3' => { desc: 'app_store_screenshot_3.html' },
      'enhanced_app_store_screenshot-4' => { desc: 'app_store_screenshot_4.html' },
      'enhanced_app_store_screenshot-5' => { desc: 'app_store_screenshot_5.html' },
      'enhanced_app_store_screenshot-6' => { desc: 'app_store_screenshot_6.html' }
    }

    download_translated_strings(
      project_url: 'https://translate.wordpress.org/projects/apps/ios/release-notes/',
      target_files: files,
      download_path: './fastlane/appstoreres/metadata'
    )
  end

  # Downloads the latest strings from GlotPress used for the creation of the Jetpack promo screenshots.
  #
  # The downloaded strings will be save in `fastlane/appstoreres/jetpack_metadata`
  #
  desc 'Downloads translated promo strings for Jetpack from GlotPress'
  lane :download_jetpack_promo_strings do
    files = {
      'screenshot-text-1' => { desc: 'app_store_screenshot_1.txt' },
      'screenshot-text-2' => { desc: 'app_store_screenshot_2.txt' },
      'screenshot-text-3' => { desc: 'app_store_screenshot_3.txt' },
      'screenshot-text-4' => { desc: 'app_store_screenshot_4.txt' },
      'screenshot-text-5' => { desc: 'app_store_screenshot_5.txt' },
      'screenshot-text-6' => { desc: 'app_store_screenshot_6.txt' }
    }

    download_translated_strings(
      project_url: 'https://translate.wordpress.com/projects/jetpack/apps/ios/release-notes/',
      target_files: files,
      download_path: './fastlane/appstoreres/jetpack_metadata'
    )
  end

  ########################################################################
  # Helper Lanes
  ########################################################################

  # Private lane to download the specified translated strings from GlotPress
  #
  # @called_by download_promo_strings, download_jetpack_promo_strings
  #
  desc 'Downloads translated strings from GlotPress'
  private_lane :download_translated_strings do |options|
    gp_downloadmetadata(
      project_url: options[:project_url],
      target_files: options[:target_files],
      locales: GLOTPRESS_TO_ASC_METADATA_LOCALE_CODES,
      source_locale: 'en-US',
      download_path: options[:download_path]
    )
  end

  # Create simulators needed for the `screenshots` lane if they don't exist yet
  #
  # Note: Be sure to call this lane after `xcodebuild` has been invoked at least once in the VM / local machine
  # because on a fresh VM where Xcode has never launched yet, there might be no simulator at all, but as soon as
  # Xcode is launched for the first time it will create a set of defaut simulators.
  #
  # We only want to create the missing simulators for screenshots if they don't exist in the default set created
  # after the first `xcodebuild` launch, otherwise if we create a simulator while it will also be created by Xcode
  # later, we'll end up with `The requested device could not be found because multiple devices matched the request.`
  # when we try to run `capture_ios_screenshots`
  #
  lane :create_missing_simulators_for_screenshots do
    specs = JSON.parse(`xcrun simctl list -j`)
    SCREENSHOT_SIMULATORS.each do |device_name|
      device_spec = specs['devicetypes'].find { |dt| dt['name'] == device_name }
      UI.user_error!("Could not find device type named `#{device_name}` in `xcrun simctl list`") if device_spec.nil?
      device_type_id = device_spec['identifier']

      already_exists = specs['devices'].any? { |_, dev_list| dev_list.any? { |dev_spec| dev_spec['deviceTypeIdentifier'] == device_type_id } }
      step_name = "Creating simulator for device type #{device_name}"
      if already_exists
        Actions.execute_action(step_name) { UI.message "A simulator for device type #{device_type_id} already exists" }
      else
        sh('xcrun', 'simctl', 'create', device_name, device_type_id, step_name:)
        # To get the UUID of the created Simulator, store the `sh` call above in a variable, e.g. `res = sh(...`, then call:
        # res.split("\n").find { |line| line.match?(/^[0-9A-F-]+$/) }&.chomp # UUID of the created simulator
      end
    end
  end
end
