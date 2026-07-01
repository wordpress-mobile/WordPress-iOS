# frozen_string_literal: true

#################################################
# Lanes
#################################################

# Lanes related to Generating Screenshots
#
platform :ios do
  # Generates the promo screenshots for WordPress from the raw screenshots and the `screenshots.json` assembly description file.
  #
  # @see https://github.com/wordpress-mobile/release-toolkit/blob/trunk/docs/screenshot-compositor.md for documentation
  #
  # - Raw screenshots are expected to be in the `screenshots/`
  # - Localized metadata for the screenshots are expected to be in `appstoreres/metadata`
  # - Generated promo screenshots will be generated in `fastlane/promo_screenshots`
  #
  desc 'Creates promo screenshots'
  lane :create_promo_screenshots do |options|
    # All file paths are relative to the `Fastfile`.
    promo_screenshots(
      orig_folder: 'screenshots',
      metadata_folder: 'appstoreres/metadata',
      output_folder: WORDPRESS_PROMO_SCREENSHOTS_PATH,
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
      output_folder: JETPACK_PROMO_SCREENSHOTS_PATH,
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
end
