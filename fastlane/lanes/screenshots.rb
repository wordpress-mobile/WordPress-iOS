# frozen_string_literal: true

require 'English'
require 'json'
require 'tmpdir'
require_relative 'screenshot_content_helper'

# The simulators the Jetpack App Store screenshots are taken on, by name. Their screenshots are the
# sizes the App Store asks for: 6.9" iPhone (1320×2868), 13" iPad (2064×2752), and the iPhone Duo's
# outer (1398×2034) and inner (2007×2853) displays. Each gets a simulator of its own, named
# "Screenshots <name>", so that overriding its status bar doesn't touch the simulators used for
# anything else.
#
# - `type`: the simulator's device type.
# - `sdk`: the oldest iOS SDK the app has to be built with for the device. Built with an older one,
#   an app runs letterboxed on the iPhone Duo's outer display.
# - `inner_display`: the iPhone Duo's inner display, in points. The simulator only models the outer
#   one, so the lane shows the inner one by moving the app to a resizable display of its size.
JETPACK_SCREENSHOT_DEVICES = {
  'iPhone 18 Pro Max' => { type: 'com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro-Max' },
  'iPad Pro 13-inch (M5)' => { type: 'com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB' },
  'iPhone Duo' => { type: 'com.apple.CoreSimulator.SimDeviceType.iPhone-Duo', sdk: '27.1', inner_display: '669x951' }
}.freeze

# How long one run of the screenshot test, for one device and language, may take.
JETPACK_SCREENSHOT_RUN_TIMEOUT = 20 * 60

JETPACK_RAW_SCREENSHOTS_PATH = File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'jetpack_screenshots')
JETPACK_SCREENSHOTS_OVERVIEW_PATH = File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'jetpack_screenshots_overview')
JETPACK_SCREENSHOT_TEXT_PATH = File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'appstoreres', 'jetpack_metadata')
# The fixtures' content, translated for the screenshots: `en.json` holds the English exactly as it
# is in the fixtures, by key, and `<locale>.json` the translations. See `ScreenshotContentHelper`.
JETPACK_SCREENSHOT_CONTENT_PATH = File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'appstoreres', 'jetpack_screenshot_content')
UI_TEST_FIXTURES_PATH = File.join(PROJECT_ROOT_FOLDER, 'Tests', 'JetpackUITests', 'Fixtures')

SCREENSHOT_COMPOSITOR_PATH = File.join(PROJECT_ROOT_FOLDER, 'Scripts', 'app-store-screenshots', 'compose.swift')

# The strings drawn on the Jetpack screenshots, by GlotPress key, with the file each is kept in under
# `fastlane/appstoreres/jetpack_metadata/<locale>/`. The English source is in its `source` folder.
JETPACK_SCREENSHOT_STRINGS = {
  'screenshot-title' => 'screenshot_title.txt',
  **(1..4).flat_map do |i|
    [
      ["screenshot-#{i}-feature", "screenshot_#{i}_feature.txt"],
      ["screenshot-#{i}-headline", "screenshot_#{i}_headline.txt"]
    ]
  end.to_h
}.freeze

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

  # Takes the raw Jetpack screenshots: runs the `AppStoreScreenshots` UI test once per device and
  # language, against the HTTP fixtures, and saves its screenshots to `fastlane/jetpack_screenshots`.
  #
  # See docs/app-store-screenshots.md.
  #
  # @option [String] language Comma-separated App Store locales, such as `de-DE,ja`. Defaults to every
  #   locale that has all of the screenshot strings, since the others are left out of the final screenshots.
  # @option [String] device One of the names in `JETPACK_SCREENSHOT_DEVICES`. Defaults to all of them.
  # @option [Boolean] skip_build Use the app already built in `DerivedData`, from an earlier run.
  #
  # @example Iterate on one language and device:
  #   bundle exec fastlane jetpack_screenshots language:en-US device:"iPhone 18 Pro Max" skip_build:true
  #
  desc 'Takes the raw Jetpack App Store screenshots'
  lane :jetpack_screenshots do |language: nil, device: nil, skip_build: false|
    devices = JETPACK_SCREENSHOT_DEVICES.select { |name, _| device.nil? || name == device }
    UI.user_error!("Unknown device #{device}. Choose one of: #{JETPACK_SCREENSHOT_DEVICES.keys.join(', ')}") if devices.empty?

    sdk = sh('xcrun', '--sdk', 'iphonesimulator', '--show-sdk-version', log: false).strip
    devices.each do |name, settings|
      next if settings[:sdk].nil? || Gem::Version.new(sdk) >= Gem::Version.new(settings[:sdk])

      UI.user_error!(<<~MESSAGE)
        #{name} screenshots need the iOS #{settings[:sdk]} SDK, from Xcode #{settings[:sdk]} or later, and this Xcode has iOS #{sdk}.
        Select a newer Xcode (for example, `DEVELOPER_DIR=/Applications/Xcode-#{settings[:sdk]}.0.app/Contents/Developer`), or leave the device out with `device:`.
      MESSAGE
    end

    build_jetpack_for_testing(http_fixtures: true) unless skip_build

    xctestrun = Dir.glob(File.join(DERIVED_DATA_PATH, 'Build', 'Products', '*JetpackUITests*.xctestrun')).first
    UI.user_error!('No JetpackUITests build found. Run this without skip_build:true.') if xctestrun.nil?

    # A build from an earlier run may be from an older Xcode than this one.
    app_info = File.join(DERIVED_DATA_PATH, 'Build', 'Products', 'Debug-iphonesimulator', 'Jetpack.app', 'Info.plist')
    built_sdk = sh('/usr/libexec/PlistBuddy', '-c', 'Print :DTSDKName', app_info, log: false)[/[\d.]+/]
    devices.each do |name, settings|
      next if settings[:sdk].nil? || Gem::Version.new(built_sdk) >= Gem::Version.new(settings[:sdk])

      UI.user_error!("The app was built with the iOS #{built_sdk} SDK, and #{name} screenshots need #{settings[:sdk]}. Run this without skip_build:true.")
    end

    locales = language ? language.split(',').map(&:strip) : jetpack_screenshot_locales
    results = File.join(PROJECT_ROOT_FOLDER, 'build', 'results', 'screenshots')
    FileUtils.mkdir_p(results)

    failures = []
    devices.each do |name, settings|
      udid = prepare_screenshot_simulator(name: "Screenshots #{name}", device_type: settings[:type])
      locales.each do |locale|
        UI.header("#{name}: #{locale}")
        run = File.join(results, "#{name}-#{locale}")
        FileUtils.rm_rf("#{run}.xcresult")
        # xcodebuild hands variables prefixed with TEST_RUNNER_ to the test, without the prefix.
        environment = {
          'TEST_RUNNER_SCREENSHOTS_OUTPUT_DIR' => JETPACK_RAW_SCREENSHOTS_PATH,
          'TEST_RUNNER_SCREENSHOTS_LANGUAGE' => locale
        }
        overlay = translated_fixtures(locale)
        if overlay
          environment['TEST_RUNNER_SCREENSHOTS_FIXTURES_OVERLAY'] = overlay
          # The test finds the posts it opens by their titles, which are translated too.
          environment['TEST_RUNNER_SCREENSHOTS_CONTENT'] = File.join(JETPACK_SCREENSHOT_CONTENT_PATH, "#{locale}.json")
        end
        requests = nil
        if settings[:inner_display]
          requests = Dir.mktmpdir('inner-display-requests')
          environment['TEST_RUNNER_SCREENSHOTS_INNER_DISPLAY_REQUESTS'] = requests
        end

        command = [
          'xcodebuild', 'test-without-building',
          '-xctestrun', xctestrun,
          '-destination', "id=#{udid}",
          '-only-testing:JetpackUITests/AppStoreScreenshots',
          # After a UI test run Xcode otherwise spends up to ten minutes on `simctl diagnose`.
          '-collect-test-diagnostics', 'never',
          '-resultBundlePath', "#{run}.xcresult"
        ]
        pid = Process.spawn(environment, *command, %i[out err] => "#{run}.log")
        # A run takes around three minutes, and longer on the iPhone Duo. One that's taken much
        # longer has stopped, and is ended so that the other runs still happen.
        deadline = Time.now + JETPACK_SCREENSHOT_RUN_TIMEOUT
        until Process.waitpid(pid, Process::WNOHANG)
          answer_inner_display_requests(requests, udid: udid, size: settings[:inner_display]) if requests
          if Time.now > deadline
            UI.error("#{name}: #{locale} has taken more than #{JETPACK_SCREENSHOT_RUN_TIMEOUT / 60} minutes, so it's being stopped.")
            Process.kill('INT', pid)
            Process.kill('KILL', pid) unless exited_within?(pid, timeout: 30)
            break
          end
          sleep(0.5)
        end
        Process.wait(pid) if process_running?(pid)
        failures << "#{name}: #{locale} (see #{run}.log and #{run}.xcresult)" unless $CHILD_STATUS&.success?
        FileUtils.rm_rf([requests, overlay].compact)
      end
    end

    UI.user_error!("The screenshots failed for:\n#{failures.join("\n")}") unless failures.empty?
    UI.success("Raw screenshots are in #{JETPACK_RAW_SCREENSHOTS_PATH}. Next, run `create_jetpack_promo_screenshots`.")
  end

  # Composes the Jetpack App Store screenshots from the raw ones `jetpack_screenshots` takes: each gets
  # its headline above it, fitted to its language, and is set in a device frame.
  #
  # - Raw screenshots are read from `fastlane/jetpack_screenshots`
  # - The headlines are read from `fastlane/appstoreres/jetpack_metadata/<locale>/screenshot_*.txt`
  # - The final screenshots are written to `fastlane/jetpack_promo_screenshots`, ready for
  #   `update_jetpack_metadata_on_app_store_connect with_screenshots:true`
  # - An overview of each locale, every screenshot side by side, is written to
  #   `fastlane/jetpack_screenshots_overview`, for checking them all at a glance
  #
  desc 'Creates the Jetpack App Store screenshots from the raw screenshots'
  lane :create_jetpack_promo_screenshots do
    # Start from nothing, so that no screenshot from an earlier run is uploaded by mistake.
    FileUtils.rm_rf([JETPACK_PROMO_SCREENSHOTS_PATH, JETPACK_SCREENSHOTS_OVERVIEW_PATH])
    sh(
      'xcrun', 'swift', SCREENSHOT_COMPOSITOR_PATH,
      JETPACK_RAW_SCREENSHOTS_PATH,
      JETPACK_SCREENSHOT_TEXT_PATH,
      JETPACK_PROMO_SCREENSHOTS_PATH,
      JETPACK_SCREENSHOTS_OVERVIEW_PATH
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
    download_translated_strings(
      project_url: 'https://translate.wordpress.com/projects/jetpack/apps/ios/release-notes/',
      target_files: JETPACK_SCREENSHOT_STRINGS.transform_values { |file| { desc: file } },
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

  # Takes the iPhone Duo inner display screenshots the `AppStoreScreenshots` test has asked for.
  #
  # For each request, this moves the app to a resizable display the inner display's size (`unfolds`
  # it), screenshots that display to the path the request names, moves the app back, and answers.
  # The test can't do any of it itself: it runs in the simulator, and can't tap on that display.
  def answer_inner_display_requests(requests, udid:, size:)
    Dir.glob(File.join(requests, '*.request')).each do |request|
      output = File.read(request).strip
      File.delete(request)

      resize = Process.spawn(
        'xcrun', 'devicectl', 'device', 'appResize', 'start', '--device', udid, '--preferred-size', size,
        %i[out err] => File::NULL
      )
      # Give the app time to move and lay itself out for the larger display.
      sleep(5)
      sh('xcrun', 'simctl', 'io', udid, 'screenshot', '--display=Resizable', output, log: false)
      # Stopping the resize session folds the app back onto the outer display. It doesn't always
      # stop when it's asked to, and then it's made to.
      Process.kill('INT', resize)
      Process.kill('KILL', resize) unless exited_within?(resize, timeout: 15)
      Process.wait(resize) if process_running?(resize)

      FileUtils.touch(request.sub(/\.request$/, '.done'))
    end
  end

  # Waits up to `timeout` seconds for the child process `pid` to exit, and returns whether it did.
  def exited_within?(pid, timeout:)
    deadline = Time.now + timeout
    while Time.now < deadline
      return true if Process.waitpid(pid, Process::WNOHANG)

      sleep(0.2)
    end
    false
  end

  # Whether the child process `pid` hasn't been waited for yet.
  def process_running?(pid)
    Process.waitpid(pid, Process::WNOHANG).nil?
  rescue Errno::ECHILD
    false
  end

  # Writes the fixtures with their content translated into `locale` to a temporary directory, and
  # returns it, or nil when there's no translation of the content for that locale, which leaves it
  # in English.
  def translated_fixtures(locale)
    translations = File.join(JETPACK_SCREENSHOT_CONTENT_PATH, "#{locale}.json")
    return nil unless File.exist?(translations)

    english = JSON.parse(File.read(File.join(JETPACK_SCREENSHOT_CONTENT_PATH, 'en.json')))
    translated = JSON.parse(File.read(translations))
    report_mismatched_content_keys(locale, english: english, translated: translated)

    overlay = Dir.mktmpdir("fixtures-#{locale}")
    ScreenshotContentHelper.write_overlay(fixtures: UI_TEST_FIXTURES_PATH, english: english, translated: translated, output: overlay)
    overlay
  end

  def report_mismatched_content_keys(locale, english:, translated:)
    mismatched = ScreenshotContentHelper.mismatched_keys(english: english, translated: translated)
    UI.important("#{locale}: no translation for #{mismatched[:missing].join(', ')}, which stays in English.") unless mismatched[:missing].empty?
    UI.important("#{locale}: #{mismatched[:unknown].join(', ')} isn't in en.json, so it's ignored.") unless mismatched[:unknown].empty?
  end

  # The locales that have every string the Jetpack screenshots need.
  def jetpack_screenshot_locales
    Dir.children(JETPACK_SCREENSHOT_TEXT_PATH).sort.select do |locale|
      next false if locale == 'source'

      JETPACK_SCREENSHOT_STRINGS.values.all? do |file|
        path = File.join(JETPACK_SCREENSHOT_TEXT_PATH, locale, file)
        File.exist?(path) && !File.read(path).strip.empty?
      end
    end
  end

  # The UDID of the simulator called `name`, created on the newest iOS runtime if there isn't one.
  def find_or_create_simulator(name:, device_type:)
    devices = JSON.parse(sh('xcrun', 'simctl', 'list', 'devices', 'available', '--json', log: false))['devices']
    udid = devices.values.flatten.find { |d| d['name'] == name }&.fetch('udid')
    return udid unless udid.nil?

    sh('xcrun', 'simctl', 'create', name, device_type, newest_ios_runtime, log: false).strip
  end

  # The identifier of the newest iOS simulator runtime installed.
  def newest_ios_runtime
    runtimes = JSON.parse(sh('xcrun', 'simctl', 'list', 'runtimes', 'available', '--json', log: false))['runtimes']
    runtime = runtimes.select { |r| r['platform'] == 'iOS' }.max_by { |r| Gem::Version.new(r['version']) }
    UI.user_error!('No iOS simulator runtime is installed.') if runtime.nil?
    runtime['identifier']
  end

  # Finds or creates the simulator called `name`, boots it, and sets it up to look the same in every
  # screenshot: light mode, and a status bar that shows 9:41, full signal and a full battery.
  #
  # @return [String] The simulator's UDID.
  def prepare_screenshot_simulator(name:, device_type:)
    udid = find_or_create_simulator(name: name, device_type: device_type)

    sh('xcrun', 'simctl', 'boot', udid, error_callback: ->(_) {}) # It may already be booted.
    sh('xcrun', 'simctl', 'bootstatus', udid, log: false)
    sh('xcrun', 'simctl', 'ui', udid, 'appearance', 'light')
    sh(
      'xcrun', 'simctl', 'status_bar', udid, 'override',
      '--time', '9:41',
      '--dataNetwork', 'wifi', '--wifiMode', 'active', '--wifiBars', '3',
      '--cellularMode', 'active', '--cellularBars', '4', '--operatorName', '',
      '--batteryState', 'charged', '--batteryLevel', '100'
    )
    udid
  end
end
