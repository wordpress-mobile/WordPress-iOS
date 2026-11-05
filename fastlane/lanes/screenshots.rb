# frozen_string_literal: true

require 'English'
require 'json'
require 'tmpdir'
require_relative 'screenshot_content_helper'

# The simulators the App Store screenshots are taken on, by name. Their screenshots are the sizes
# the App Store asks for: 6.9" iPhone (1320×2868), 13" iPad (2064×2752), and the iPhone Duo's outer
# (1398×2034) and inner (2007×2853) displays. Each gets a simulator of its own, named
# "Screenshots <name>", so that overriding its status bar doesn't touch the simulators used for
# anything else.
#
# - `type`: the simulator's device type.
# - `sdk`: the oldest iOS SDK the app has to be built with for the device. Built with an older one,
#   an app runs letterboxed on the iPhone Duo's outer display.
# - `inner_display`: the iPhone Duo's inner display, in points. The simulator only models the outer
#   one, so the lane shows the inner one by moving the app to a resizable display of its size.
SCREENSHOT_DEVICES = {
  'iPhone 18 Pro Max' => { type: 'com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro-Max' },
  'iPad Pro 13-inch (M5)' => { type: 'com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB' },
  'iPhone Duo' => { type: 'com.apple.CoreSimulator.SimDeviceType.iPhone-Duo', sdk: '27.1', inner_display: '669x951' }
}.freeze

# How long one run of the screenshot test, for one app, device and language, may take.
SCREENSHOT_RUN_TIMEOUT = 20 * 60

# The fixtures' content, translated for the screenshots: `en.json` holds the English exactly as it
# is in the fixtures, by key, and `<locale>.json` the translations. Both apps' screenshots show the
# same fixtures. See `ScreenshotContentHelper`.
SCREENSHOT_CONTENT_PATH = File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'appstoreres', 'screenshot_content')
UI_TEST_FIXTURES_PATH = File.join(PROJECT_ROOT_FOLDER, 'Tests', 'JetpackUITests', 'Fixtures')

SCREENSHOT_COMPOSITOR_PATH = File.join(PROJECT_ROOT_FOLDER, 'Scripts', 'app-store-screenshots', 'compose.swift')

# The strings drawn on an app's screenshots, by GlotPress key, with the file each is kept in under
# its `text` folder's `<locale>/`, for a title screen followed by `count` screenshots. The English
# source is in the `source` folder.
def screenshot_strings(count)
  {
    'screenshot-title' => 'screenshot_title.txt',
    **(1..count).flat_map do |i|
      [
        ["screenshot-#{i}-feature", "screenshot_#{i}_feature.txt"],
        ["screenshot-#{i}-headline", "screenshot_#{i}_headline.txt"]
      ]
    end.to_h
  }.freeze
end

# The apps whose App Store screenshots are generated, by the name the lanes take.
#
# - `bundle_id`: the app the `AppStoreScreenshots` UI test launches. The test target is Jetpack's,
#   and launches any other app by its bundle identifier, once the lane has installed it.
# - `product`: the app as built in `DerivedData`.
# - `raw`: where `take_app_store_screenshots` saves the raw screenshots.
# - `text`: the headlines, a folder per locale. See `strings`.
# - `promo`: where the composed screenshots go, for `deliver` to upload.
# - `overview`: an image per locale and device of all its composed screenshots, for review.
# - `logo`: drawn on the title screen.
# - `fixtures`: fixtures only the app's screenshots load, over the UI tests' ones. Its `mappings` folder
#   is laid out like theirs, and replaces any of their files at the same path. Images go in the UI
#   tests' `__files`, since `bodyFileName` is read from there.
SCREENSHOT_APPS = {
  'jetpack' => {
    name: 'Jetpack',
    bundle_id: 'com.automattic.jetpack',
    product: 'Jetpack.app',
    raw: File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'jetpack_screenshots'),
    text: File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'appstoreres', 'jetpack_metadata'),
    promo: JETPACK_PROMO_SCREENSHOTS_PATH,
    overview: File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'jetpack_screenshots_overview'),
    logo: File.join(PROJECT_ROOT_FOLDER, 'Sources', 'Jetpack', 'Resources', 'Assets.xcassets', 'wp-jp-circular-lockup.imageset', 'wp-jp-circular-lockup.pdf'),
    strings: screenshot_strings(4)
  },
  'wordpress' => {
    name: 'WordPress',
    bundle_id: 'org.wordpress',
    product: 'WordPress.app',
    raw: File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'wordpress_screenshots'),
    text: File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'appstoreres', 'metadata'),
    promo: WORDPRESS_PROMO_SCREENSHOTS_PATH,
    overview: File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'wordpress_screenshots_overview'),
    logo: File.join(PROJECT_ROOT_FOLDER, 'WordPress', 'Resources', 'AppImages.xcassets', 'icon-wp-filled.imageset', 'icon-wp-filled.pdf'),
    # The fixture site as an Atomic one, whose custom post types the app shows, with a Staff type.
    fixtures: File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'appstoreres', 'screenshot_fixtures', 'wordpress'),
    strings: screenshot_strings(4)
  }
}.freeze

JETPACK_SCREENSHOT_STRINGS = SCREENSHOT_APPS['jetpack'][:strings]
WORDPRESS_SCREENSHOT_STRINGS = SCREENSHOT_APPS['wordpress'][:strings]

#################################################
# Lanes
#################################################

# Lanes related to Generating Screenshots
#
platform :ios do
  # Takes the raw Jetpack App Store screenshots: runs the `AppStoreScreenshots` UI test once per
  # device and language, against the HTTP fixtures, and saves its screenshots to
  # `fastlane/jetpack_screenshots`. See `take_app_store_screenshots` for the options, and
  # docs/app-store-screenshots.md.
  #
  # @example Iterate on one language and device:
  #   bundle exec fastlane jetpack_screenshots language:en-US device:"iPhone 18 Pro Max" skip_build:true
  #
  desc 'Takes the raw Jetpack App Store screenshots'
  lane :jetpack_screenshots do |options|
    take_app_store_screenshots(app: 'jetpack', **options.to_h.slice(:language, :device, :skip_build))
  end

  # Takes the raw WordPress App Store screenshots, to `fastlane/wordpress_screenshots`. The same as
  # `jetpack_screenshots`, with the WordPress app.
  #
  desc 'Takes the raw WordPress App Store screenshots'
  lane :wordpress_screenshots do |options|
    take_app_store_screenshots(app: 'wordpress', **options.to_h.slice(:language, :device, :skip_build))
  end

  # Builds what `jetpack_screenshots` and `wordpress_screenshots` run: the Jetpack app and its UI
  # tests, and for WordPress the WordPress app too, all with the HTTP fixtures compiled in.
  #
  # @option [String] app `jetpack` or `wordpress`.
  #
  # @called_by CI
  #
  desc 'Builds an app for taking its App Store screenshots'
  lane :build_for_app_store_screenshots do |app:|
    screenshot_app(app)
    build_jetpack_for_testing(http_fixtures: true)
    next unless app == 'wordpress'

    # A plain build: the UI tests that drive it are Jetpack's, built above. It's for a simulator, as
    # that build is, rather than a generic destination, so that the packages they share are built
    # with the same settings, once.
    name, settings = SCREENSHOT_DEVICES.first
    simulator = find_or_create_simulator(name: "Screenshots #{name}", device_type: settings[:type])
    sh(
      'xcodebuild', 'build',
      '-workspace', WORKSPACE_PATH,
      '-scheme', 'WordPress',
      '-configuration', 'Debug',
      '-destination', "platform=iOS Simulator,id=#{simulator}",
      '-derivedDataPath', DERIVED_DATA_PATH,
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) UI_TEST_HTTP_FIXTURES'
    )
  end

  # Takes an app's App Store screenshots on CI, in every language on every device, by starting
  # `.buildkite/app-store-screenshots.yml` on the current branch. It runs a job per device and
  # language, then one that composes them; the composed screenshots are its artifacts.
  #
  # Starting a build needs a Buildkite API token in `BUILDKITE_TOKEN`.
  #
  # @option [String] app `jetpack` (the default) or `wordpress`.
  #
  desc 'Takes the App Store screenshots on CI'
  lane :trigger_app_store_screenshots do |app: 'jetpack'|
    settings = screenshot_app(app)
    build_url = buildkite_trigger_build(
      buildkite_organization: BUILDKITE_ORGANIZATION,
      buildkite_pipeline: BUILDKITE_PIPELINE,
      branch: git_branch,
      pipeline_file: 'app-store-screenshots.yml',
      message: "#{settings[:name]} App Store Screenshots",
      environment: { SCREENSHOTS_APP: app }
    )
    UI.success("Screenshots build started: #{build_url}")
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
    compose_app_store_screenshots(app: 'jetpack')
  end

  # Composes the WordPress App Store screenshots, the same way as `create_jetpack_promo_screenshots`:
  #
  # - Raw screenshots are read from `fastlane/wordpress_screenshots`
  # - The headlines are read from `fastlane/appstoreres/metadata/<locale>/screenshot_*.txt`
  # - The final screenshots are written to `fastlane/promo_screenshots`, ready for
  #   `update_wordpress_metadata_on_app_store_connect with_screenshots:true`
  # - The overviews are written to `fastlane/wordpress_screenshots_overview`
  #
  desc 'Creates the WordPress App Store screenshots from the raw screenshots'
  lane :create_promo_screenshots do
    compose_app_store_screenshots(app: 'wordpress')
  end

  # Downloads the latest strings from GlotPress used for the creation of the WordPress promo screenshots.
  #
  # The downloaded strings will be save in `fastlane/appstoreres/metadata`
  #
  desc 'Downloads translated promo strings for WordPress from GlotPress'
  lane :download_promo_strings do
    download_translated_strings(
      project_url: 'https://translate.wordpress.org/projects/apps/ios/release-notes/',
      target_files: WORDPRESS_SCREENSHOT_STRINGS.transform_values { |file| { desc: file } },
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

  # The settings in `SCREENSHOT_APPS` for `app`.
  def screenshot_app(app)
    SCREENSHOT_APPS.fetch(app) { UI.user_error!("Unknown app #{app}. Choose one of: #{SCREENSHOT_APPS.keys.join(', ')}") }
  end

  # Takes the raw App Store screenshots of `app`: runs the `AppStoreScreenshots` UI test once per
  # device and language, against the HTTP fixtures, and saves its screenshots to the app's `raw` folder.
  #
  # @param [String] language Comma-separated App Store locales, such as `de-DE,ja`. Defaults to every
  #   locale that has all of the app's screenshot strings, since the others are left out of the final
  #   screenshots.
  # @param [String] device One of the names in `SCREENSHOT_DEVICES`. Defaults to all of them.
  # @param [Boolean] skip_build Use the app already built in `DerivedData`, from an earlier run.
  #
  # rubocop:disable-next Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def take_app_store_screenshots(app:, language: nil, device: nil, skip_build: false)
    settings = screenshot_app(app)
    devices = SCREENSHOT_DEVICES.select { |name, _| device.nil? || name == device }
    UI.user_error!("Unknown device #{device}. Choose one of: #{SCREENSHOT_DEVICES.keys.join(', ')}") if devices.empty?

    sdk = sh('xcrun', '--sdk', 'iphonesimulator', '--show-sdk-version', log: false).strip
    devices.each do |name, device_settings|
      next if device_settings[:sdk].nil? || Gem::Version.new(sdk) >= Gem::Version.new(device_settings[:sdk])

      UI.user_error!(<<~MESSAGE)
        #{name} screenshots need the iOS #{device_settings[:sdk]} SDK, from Xcode #{device_settings[:sdk]} or later, and this Xcode has iOS #{sdk}.
        Select a newer Xcode (for example, `DEVELOPER_DIR=/Applications/Xcode-#{device_settings[:sdk]}.0.app/Contents/Developer`), or leave the device out with `device:`.
      MESSAGE
    end

    build_for_app_store_screenshots(app: app) unless skip_build

    xctestrun = Dir.glob(File.join(DERIVED_DATA_PATH, 'Build', 'Products', '*JetpackUITests*.xctestrun')).max_by { |f| File.mtime(f) }
    UI.user_error!('No JetpackUITests build found. Run this without skip_build:true.') if xctestrun.nil?

    # A build from an earlier run may be from an older Xcode than this one, or not be there at all.
    app_path = File.join(DERIVED_DATA_PATH, 'Build', 'Products', 'Debug-iphonesimulator', settings[:product])
    UI.user_error!("No #{settings[:product]} build found. Run this without skip_build:true.") unless File.exist?(app_path)
    built_sdk = sh('/usr/libexec/PlistBuddy', '-c', 'Print :DTSDKName', File.join(app_path, 'Info.plist'), log: false)[/[\d.]+/]
    devices.each do |name, device_settings|
      next if device_settings[:sdk].nil? || Gem::Version.new(built_sdk) >= Gem::Version.new(device_settings[:sdk])

      UI.user_error!("#{settings[:product]} was built with the iOS #{built_sdk} SDK, and #{name} screenshots need #{device_settings[:sdk]}. Run this without skip_build:true.")
    end

    locales = language ? language.split(',').map(&:strip) : screenshot_locales(settings)
    results = File.join(PROJECT_ROOT_FOLDER, 'build', 'results', 'screenshots')
    FileUtils.mkdir_p(results)

    failures = []
    devices.each do |name, device_settings|
      udid = prepare_screenshot_simulator(name: "Screenshots #{name}", device_type: device_settings[:type])
      # The test run installs the Jetpack app, its own target. Any other app is installed here.
      sh('xcrun', 'simctl', 'install', udid, app_path) unless app == 'jetpack'
      locales.each do |locale|
        UI.header("#{settings[:name]}, #{name}: #{locale}")
        run = File.join(results, "#{app}-#{name}-#{locale}")
        FileUtils.rm_rf("#{run}.xcresult")
        # xcodebuild hands variables prefixed with TEST_RUNNER_ to the test, without the prefix.
        environment = {
          'TEST_RUNNER_SCREENSHOTS_APP' => settings[:bundle_id],
          'TEST_RUNNER_SCREENSHOTS_OUTPUT_DIR' => settings[:raw],
          'TEST_RUNNER_SCREENSHOTS_LANGUAGE' => locale
        }
        overlay = screenshot_fixtures(settings, locale)
        environment['TEST_RUNNER_SCREENSHOTS_FIXTURES_OVERLAY'] = overlay if overlay
        if File.exist?(File.join(SCREENSHOT_CONTENT_PATH, "#{locale}.json"))
          # The test finds the posts it opens by their titles, which are translated too.
          environment['TEST_RUNNER_SCREENSHOTS_CONTENT'] = File.join(SCREENSHOT_CONTENT_PATH, "#{locale}.json")
        end
        requests = nil
        if device_settings[:inner_display]
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
        deadline = Time.now + SCREENSHOT_RUN_TIMEOUT
        until Process.waitpid(pid, Process::WNOHANG)
          answer_inner_display_requests(requests, udid: udid, size: device_settings[:inner_display]) if requests
          if Time.now > deadline
            UI.error("#{name}: #{locale} has taken more than #{SCREENSHOT_RUN_TIMEOUT / 60} minutes, so it's being stopped.")
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
    compose_lane = app == 'jetpack' ? 'create_jetpack_promo_screenshots' : 'create_promo_screenshots'
    UI.success("Raw screenshots are in #{settings[:raw]}. Next, run `#{compose_lane}`.")
  end

  # Composes the App Store screenshots of `app` from its raw ones. See `create_jetpack_promo_screenshots`.
  def compose_app_store_screenshots(app:)
    settings = screenshot_app(app)
    # Start from nothing, so that no screenshot from an earlier run is uploaded by mistake.
    FileUtils.rm_rf([settings[:promo], settings[:overview]])
    sh(
      'xcrun', 'swift', SCREENSHOT_COMPOSITOR_PATH,
      '--logo', settings[:logo],
      settings[:raw],
      settings[:text],
      settings[:promo],
      settings[:overview]
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

  # Writes the fixtures `app`'s screenshots in `locale` load over the UI tests' fixtures to a temporary
  # directory, and returns it, or nil when there are none:
  #
  # - The app's own fixtures, from its `fixtures` folder, if it has one: content that's only in its
  #   screenshots.
  # - Every fixture with content to translate, translated into `locale`, when there's a translation of
  #   the content for that locale. Without one, the content stays in English.
  # rubocop:disable-next Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def screenshot_fixtures(settings, locale)
    own = settings[:fixtures] if settings[:fixtures] && Dir.exist?(settings[:fixtures])
    translations = File.join(SCREENSHOT_CONTENT_PATH, "#{locale}.json")
    translated = JSON.parse(File.read(translations)) if File.exist?(translations)
    return nil if own.nil? && translated.nil?

    overlay = Dir.mktmpdir("fixtures-#{locale}")
    if translated
      english = JSON.parse(File.read(File.join(SCREENSHOT_CONTENT_PATH, 'en.json')))
      report_mismatched_content_keys(locale, english: english, translated: translated)
      ScreenshotContentHelper.write_overlay(fixtures: UI_TEST_FIXTURES_PATH, english: english, translated: translated, output: overlay)
    end
    return overlay if own.nil?

    # The app's own fixtures replace any UI test fixture at the same path, and are translated too.
    FileUtils.mkdir_p(File.join(overlay, 'mappings'))
    FileUtils.cp_r(File.join(own, 'mappings', '.'), File.join(overlay, 'mappings'))
    if translated
      Dir.mktmpdir('own-fixtures') do |own_translated|
        ScreenshotContentHelper.write_overlay(fixtures: own, english: english, translated: translated, output: own_translated)
        FileUtils.cp_r(File.join(own_translated, 'mappings', '.'), File.join(overlay, 'mappings')) if Dir.exist?(File.join(own_translated, 'mappings'))
      end
    end
    overlay
  end

  def report_mismatched_content_keys(locale, english:, translated:)
    mismatched = ScreenshotContentHelper.mismatched_keys(english: english, translated: translated)
    UI.important("#{locale}: no translation for #{mismatched[:missing].join(', ')}, which stays in English.") unless mismatched[:missing].empty?
    UI.important("#{locale}: #{mismatched[:unknown].join(', ')} isn't in en.json, so it's ignored.") unless mismatched[:unknown].empty?
  end

  # The locales that have every string an app's screenshots need, from its `SCREENSHOT_APPS` settings.
  def screenshot_locales(settings)
    Dir.children(settings[:text]).sort.select do |locale|
      next false if locale == 'source'

      settings[:strings].values.all? do |file|
        path = File.join(settings[:text], locale, file)
        File.exist?(path) && !File.read(path).strip.empty?
      end
    end
  end

  # The UDID of the simulator called `name`, created on the newest iOS runtime if there isn't one.
  def find_or_create_simulator(name:, device_type:)
    devices = JSON.parse(sh('xcrun', 'simctl', 'list', 'devices', 'available', '--json', log: false))['devices']
    udid = devices.values.flatten.find { |d| d['name'] == name }&.fetch('udid')
    return udid unless udid.nil?

    sh('xcrun', 'simctl', 'create', name, device_type, newest_runtime(for: device_type)).strip
  end

  # The identifier of the newest iOS simulator runtime that can run `device_type`.
  #
  # Not every runtime runs every device: iOS 27.1 runs only the iPhone Duo, so creating an iPhone 18
  # Pro Max on it fails with "Incompatible device".
  # rubocop:disable-next Metrics/AbcSize
  def newest_runtime(for:)
    device_type = binding.local_variable_get(:for)
    runtimes = JSON.parse(sh('xcrun', 'simctl', 'list', 'runtimes', 'available', '--json', log: false))['runtimes']
    runtime = runtimes
              .select { |r| r['platform'] == 'iOS' && r.fetch('supportedDeviceTypes', []).any? { |t| t['identifier'] == device_type } }
              .max_by { |r| Gem::Version.new(r['version']) }
    UI.user_error!("No iOS simulator runtime installed can run #{device_type}.") if runtime.nil?
    runtime['identifier']
  end

  # Finds or creates the simulator called `name`, boots it, and sets it up to look the same in every
  # screenshot: light mode, and a status bar that shows 9:41, full signal and a full battery.
  #
  # @return [String] The simulator's UDID.
  def prepare_screenshot_simulator(name:, device_type:)
    udid = find_or_create_simulator(name: name, device_type: device_type)

    sh('xcrun', 'simctl', 'boot', udid, error_callback: ->(_) {}) # It may already be booted.
    sh('xcrun', 'simctl', 'bootstatus', udid)
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
