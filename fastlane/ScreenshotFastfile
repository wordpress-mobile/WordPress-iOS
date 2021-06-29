require 'fileutils'

default_platform(:ios)

platform :ios do
########################################################################
# Screenshot Lanes
########################################################################
  #####################################################################################
  # screenshots
  # -----------------------------------------------------------------------------------
  # This lane generates the localised screenshots.
  # It is the same as running bundle exec fastlane snapshot, but ensures that the app
  # is only built once.
  # -----------------------------------------------------------------------------------
  # Usage:
  # bundle exec fastlane screenshots
  #
  # Example:
  # bundle exec fastlane screenshots
  #####################################################################################
  desc "Generate localised screenshots"
  lane :screenshots  do |options|

    sh('bundle exec pod install')
    FileUtils.rm_rf(DERIVED_DATA_PATH)

    scheme = options[:scheme] || "WordPressScreenshotGeneration"

    output_directory = options[:output_directory] || File.join(Dir.pwd, "/screenshots")

    scan(
      workspace: WORKSPACE_PATH,
      scheme: scheme,
      build_for_testing: true,
      derived_data_path: DERIVED_DATA_PATH,
    )

    languages = "ar-SA da de-DE en-AU en-CA en-GB es-ES fr-FR he id it ja ko no nl-NL pt-BR pt-PT ru sv th tr zh-Hans zh-Hant en-US".split(" ")

    # Allow creating screenshots for just one languages
    if options[:language] != nil
      languages.keep_if { |language|
        language.casecmp(options[:language]) == 0
      }
    end

    puts languages

    [true, false].each { | dark_mode_enabled |
      capture_ios_screenshots(
        workspace: WORKSPACE_PATH,
        scheme: scheme,
        test_without_building: true,
        derived_data_path: DERIVED_DATA_PATH,
        output_directory: output_directory,
        languages: languages,
        dark_mode: dark_mode_enabled,
        override_status_bar: true,

        reinstall_app: true,
        erase_simulator: true,
        localize_simulator: true,
        concurrent_simulators: true,

        devices: [
          "iPhone Xs Max",
          "iPhone 8 Plus",
          "iPad Pro (12.9-inch) (2nd generation)",
          "iPad Pro (12.9-inch) (3rd generation)",
        ],
      )
    }
  end

  #####################################################################################
  # jetpack_screenshots
  # -----------------------------------------------------------------------------------
  # This lane generates the localised Jetpack screenshots.
  # It is the same as running bundle exec fastlane snapshot, but ensures that the app
  # is only built once.
  # -----------------------------------------------------------------------------------
  # Usage:
  # bundle exec fastlane jetpack_screenshots
  #
  # Example:
  # bundle exec fastlane jetpack_screenshots
  #####################################################################################
  desc "Generate localised Jetpack screenshots"
  lane :jetpack_screenshots do |options|
    screenshots(
      scheme: "JetpackScreenshotGeneration",
      output_directory: File.join(Dir.pwd, "/jetpack_screenshots")
    )
  end

  #####################################################################################
  # create_promo_screenshots
  # -----------------------------------------------------------------------------------
  # This lane generates the promo screenshots.
  # Source plain screenshots are supposed to be in the screenshots_orig folder
  # If this folder doesn't exist, the system will ask to use the standard screenshot
  # folder. If the user confirms, the pictures in the screenshots folder will be
  # copied to a new screenshots_orig folder.
  # -----------------------------------------------------------------------------------
  # Usage:
  # bundle exec fastlane create_promo_screenshots
  #
  # Example:
  # bundle exec fastlane create_promo_screenshots
  #####################################################################################
  desc "Creates promo screenshots"
  lane :create_promo_screenshots do |options|

    # Run screenshots generator tool
    # All file paths are relative to the `fast file`.
    promo_screenshots(
      orig_folder: "screenshots",
      metadata_folder: "appstoreres/metadata",
      output_folder: File.join(Dir.pwd, "/promo_screenshots"),
      force: options[:force],
    )
  end

  #####################################################################################
  # create_jetpack_promo_screenshots
  # -----------------------------------------------------------------------------------
  # This lane generates the Jetpack promo screenshots.
  # Source plain screenshots are supposed to be in the screenshots_orig folder
  # If this folder doesn't exist, the system will ask to use the standard screenshot
  # folder. If the user confirms, the pictures in the screenshots folder will be
  # copied to a new screenshots_orig folder.
  # -----------------------------------------------------------------------------------
  # Usage:
  # bundle exec fastlane create_jetpack_promo_screenshots
  #
  # Example:
  # bundle exec fastlane create_jetpack_promo_screenshots
  #####################################################################################
  desc "Creates Jetpack promo screenshots"
  lane :create_jetpack_promo_screenshots do |options|

    # Run screenshots generator tool
    # All file paths are relative to the `fast file`.
    promo_screenshots(
      orig_folder: "jetpack_screenshots",
      metadata_folder: "appstoreres/jetpack_metadata",
      config_file: "jetpack_screenshots.json",
      output_folder: File.join(Dir.pwd, "/jetpack_promo_screenshots"),
      force: options[:force],
    )
  end

  #####################################################################################
  # download_promo_strings
  # -----------------------------------------------------------------------------------
  # This lane downloads the promo strings to use for the creation of the enhanced
  # screenshots.
  # -----------------------------------------------------------------------------------
  # Usage:
  # bundle exec fastlane download_promo_strings
  #
  # Example:
  # bundle exec fastlane download_promo_strings
  #####################################################################################
  desc "Downloads translated promo strings from GlotPress"
  lane :download_promo_strings do |options|
    files = {
      "app_store_screenshot-1" => {desc: "app_store_screenshot_1.txt"},
      "app_store_screenshot-2" => {desc: "app_store_screenshot_2.txt"},
      "app_store_screenshot-3" => {desc: "app_store_screenshot_3.txt"},
      "app_store_screenshot-4" => {desc: "app_store_screenshot_4.txt"},
      "app_store_screenshot-5" => {desc: "app_store_screenshot_5.txt"},
      "app_store_screenshot-6" => {desc: "app_store_screenshot_6.txt"},
      "app_store_screenshot-7" => {desc: "app_store_screenshot_7.txt"},
      "app_store_screenshot-8" => {desc: "app_store_screenshot_8.txt"},

      "enhanced_app_store_screenshot-1" => {desc: "app_store_screenshot_1.html"},
      "enhanced_app_store_screenshot-2" => {desc: "app_store_screenshot_2.html"},
      "enhanced_app_store_screenshot-3" => {desc: "app_store_screenshot_3.html"},
      "enhanced_app_store_screenshot-4" => {desc: "app_store_screenshot_4.html"},
      "enhanced_app_store_screenshot-5" => {desc: "app_store_screenshot_5.html"},
      "enhanced_app_store_screenshot-6" => {desc: "app_store_screenshot_6.html"}
    }

    download_translated_strings(
      project_url: "https://translate.wordpress.org/projects/apps/ios/release-notes/",
      target_files: files,
      download_path: "./fastlane/appstoreres/metadata"
    )
  end

  #####################################################################################
  # download_jetpack_promo_strings
  # -----------------------------------------------------------------------------------
  # This lane downloads the Jetpack promo strings to use for the creation of the enhanced
  # screenshots.
  # -----------------------------------------------------------------------------------
  # Usage:
  # bundle exec fastlane download_jetpack_promo_strings
  #
  # Example:
  # bundle exec fastlane download_jetpack_promo_strings
  #####################################################################################
  desc "Downloads translated Jetpack promo strings from GlotPress"
  lane :download_jetpack_promo_strings do |options|
    files = {
      "screenshot-text-1" => {desc: "app_store_screenshot_1.txt"},
      "screenshot-text-2" => {desc: "app_store_screenshot_2.txt"},
      "screenshot-text-3" => {desc: "app_store_screenshot_3.txt"},
      "screenshot-text-4" => {desc: "app_store_screenshot_4.txt"},
      "screenshot-text-5" => {desc: "app_store_screenshot_5.txt"},
      "screenshot-text-6" => {desc: "app_store_screenshot_6.txt"},
    }

    download_translated_strings(
      project_url: "https://translate.wordpress.com/projects/jetpack/apps/ios/release-notes/",
      target_files: files,
      download_path: "./fastlane/appstoreres/jetpack_metadata"
    )
  end

  ########################################################################
  # Helper Lanes
  ########################################################################
  desc "Downloads translated strings from GlotPress"
  private_lane :download_translated_strings do |options|
    metadata_locales = [
      ["ar", "ar-SA"],
      ["en-gb", "en-US"],
      ["en-gb", "en-GB"],
      ["en-ca", "en-CA"],
      ["en-au", "en-AU"],
      ["da", "da"],
      ["de", "de-DE"],
      ["es", "es-ES"],
      ["fr", "fr-FR"],
      ["he", "he"],
      ["id", "id"],
      ["it", "it"],
      ["ja", "ja"],
      ["ko", "ko"],
      ["nl", "nl-NL"],
      ["nb", "no"],
      ["pt-br", "pt-BR"],
      ["pt", "pt-PT"],
      ["ru", "ru"],
      ["sv", "sv"],
      ["th", "th"],
      ["tr", "tr"],
      ["zh-cn", "zh-Hans"],
      ["zh-tw", "zh-Hant"],
    ]

    gp_downloadmetadata(
      project_url: options[:project_url],
      target_files: options[:target_files],
      locales: metadata_locales,
      source_locale: "en-US",
      download_path: options[:download_path])
  end

end
