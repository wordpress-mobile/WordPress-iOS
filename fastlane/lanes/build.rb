# frozen_string_literal: true

# The names for WordPress and Jetpack are currently set but unused.
# They will be once we'll the split build step from the upload step in CI.
APP_STORE_CONNECT_BUILD_NAME_WORDPRESS = 'WordPress'
APP_STORE_CONNECT_BUILD_NAME_JETPACK = 'Jetpack'
APP_STORE_CONNECT_BUILD_NAME_READER = 'Reader'

SENTRY_ORG_SLUG = 'a8c'
SENTRY_PROJECT_SLUG_WORDPRESS = 'wordpress-ios'
SENTRY_PROJECT_SLUG_JETPACK = 'jetpack-ios'

# Prototype Builds in Firebase App Distribution
PROTOTYPE_BUILD_XCODE_CONFIGURATION = 'Release-Alpha'
FIREBASE_APP_CONFIG_WORDPRESS = {
  app_name: 'WordPress',
  app_icon: ':wordpress:', # Use Buildkite emoji
  app_id: '1:124902176124:ios:ff9714d0b53aac821620f9',
  testers_group: 'wordpress-ios---prototype-builds'
}.freeze
FIREBASE_APP_CONFIG_JETPACK = {
  app_name: 'Jetpack',
  app_icon: ':jetpack:', # Use Buildkite emoji
  app_id: '1:124902176124:ios:121c494b82f283ec1620f9',
  testers_group: 'jetpack-ios---prototype-builds'
}.freeze

# Shared options to use when invoking `build_app` (`gym`).
#
# - `manageAppVersionAndBuildNumber: false` prevents `xcodebuild` from bumping
#   the build number when extracting an archive into an IPA file. We want to
#   use the build number we set!
COMMON_EXPORT_OPTIONS = { manageAppVersionAndBuildNumber: false }.freeze

# Lanes related to Building and Testing the code
#
platform :ios do
  # Runs tests locally without CI prerequisites (env files, signing, etc.)
  #
  # @option [String] scheme The scheme to test (default: WordPress)
  # @option [String] device The Simulator device name
  # @option [String] ios_version The deployment target version
  # @option [String] only_testing Specific test target/class/method (e.g. WordPressUnitTests/MyClass/testFoo)
  # @option [Boolean] clean Whether to clean before building (default: false for incremental builds)
  #
  # @example Run all WordPress tests:
  #   bundle exec fastlane test
  # @example Run a single test class:
  #   bundle exec fastlane test only_testing:WordPressUnitTests/MyClass
  # @example Test the Jetpack scheme:
  #   bundle exec fastlane test scheme:Jetpack
  # @example Clean build before testing:
  #   bundle exec fastlane test clean:true
  #
  desc 'Run tests locally'
  lane :test do |scheme: 'WordPress', device: 'iPhone 17', ios_version: nil, only_testing: nil, clean: false|
    run_tests(
      workspace: WORKSPACE_PATH,
      scheme: scheme,
      device: device,
      derived_data_path: DERIVED_DATA_PATH,
      deployment_target_version: ios_version,
      only_testing: only_testing,
      clean: clean,
      skip_package_dependencies_resolution: !clean
    )
  end

  # Builds the WordPress app for Testing
  #
  # @option [String] device the name of the Simulator device to run the tests on
  # @option [String] ios_version the Deployment Target version to use while testing
  #
  # @called_by CI
  #
  desc 'Build WordPress for Testing'
  lane :build_wordpress_for_testing do |options|
    run_tests(
      workspace: WORKSPACE_PATH,
      scheme: 'WordPress',
      derived_data_path: DERIVED_DATA_PATH,
      build_for_testing: true,
      device: options[:device],
      deployment_target_version: options[:ios_version]
    )
  end

  # Builds the Jetpack app for Testing
  #
  # @option [String] device the name of the Simulator device to run the tests on
  # @option [String] ios_version the Deployment Target version to use while testing
  #
  # @called_by CI
  #
  desc 'Build Jetpack for Testing'
  lane :build_jetpack_for_testing do |options|
    run_tests(
      workspace: WORKSPACE_PATH,
      scheme: 'Jetpack',
      derived_data_path: DERIVED_DATA_PATH,
      build_for_testing: true,
      device: options[:device],
      deployment_target_version: options[:ios_version]
    )
  end

  # Runs tests without building the app.
  #
  # Requires a prebuilt xctestrun file and simulator destination where the tests will be run.
  #
  # @option [String] name The (partial) name of the `*.xctestrun` file to run
  # @option [String] device Name of the simulator device to run the test on
  # @option [String] ios_version The deployment target version to test on
  #
  # @called_by CI
  #
  desc 'Run tests without building'
  lane :test_without_building do |options|
    # Find the referenced .xctestrun file based on its name
    build_products_path = File.join(DERIVED_DATA_PATH, 'Build', 'Products')

    xctestrun_path = Dir.glob(File.join(build_products_path, '*.xctestrun')).select do |path|
      path.include?(options[:name])
    end.first

    UI.user_error!("Unable to find .xctestrun file at #{build_products_path}.") if xctestrun_path.nil? || !File.exist?(xctestrun_path)

    # The only supported mode runs the WordPress unit tests (xctestrun name `WordPressUnitTests`).
    run_tests(
      workspace: WORKSPACE_PATH,
      scheme: 'WordPress',
      device: options[:device],
      deployment_target_version: options[:ios_version],
      ensure_devices_found: true,
      test_without_building: true,
      xctestrun: xctestrun_path,
      output_directory: File.join(PROJECT_ROOT_FOLDER, 'build', 'results'),
      reset_simulator: true,
      result_bundle: true,
      output_types: 'junit'
    )
  end

  # Builds the WordPress app and uploads it to TestFlight, for beta-testing or final release
  #
  # @param [Boolean] skip_confirm (default: false) If true, avoids any interactive prompt
  # @param [Boolean] create_release If true, creates a GitHub Release draft after the upload, with zipped xcarchive as artefact
  # @param [Boolean] beta_release If true, the GitHub release will be marked as being a pre-release
  #
  lane :build_and_upload_app_store_connect do |skip_confirm: false, create_release: false, beta_release: false|
    ensure_git_status_clean unless is_ci

    UI.important("Building version #{release_version_current} (#{build_code_current}) and uploading to TestFlight")
    UI.user_error!('Aborted by user request') unless skip_confirm || UI.confirm('Do you want to continue?')

    sentry_check_cli_installed

    update_certs_and_profiles_wordpress_app_store

    build_app(
      scheme: 'WordPress',
      workspace: WORKSPACE_PATH,
      clean: true,
      output_directory: BUILD_PRODUCTS_PATH,
      output_name: APP_STORE_CONNECT_BUILD_NAME_WORDPRESS,
      derived_data_path: DERIVED_DATA_PATH,
      export_team_id: EXTERNAL_TEAM_ID,
      export_options: { **COMMON_EXPORT_OPTIONS, method: 'app-store' }
    )

    upload_build_to_testflight(
      ipa_path: lane_context[SharedValues::IPA_OUTPUT_PATH],
      whats_new_path: WORDPRESS_RELEASE_NOTES_PATH,
      distribution_groups: ['Internal a8c Testers', 'Public Beta Testers'],
      beta_app_description_path: WORDPRESS_BETA_APP_DESCRIPTION_PATH
    )

    sentry_debug_files_upload(
      auth_token: get_required_env('SENTRY_AUTH_TOKEN'),
      org_slug: SENTRY_ORG_SLUG,
      project_slug: SENTRY_PROJECT_SLUG_WORDPRESS,
      path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
    )

    upload_gutenberg_sourcemaps(
      sentry_project_slug: SENTRY_PROJECT_SLUG_WORDPRESS,
      release_version: release_version_current,
      build_version: build_code_current,
      app_identifier: WORDPRESS_BUNDLE_IDENTIFIER
    )

    next unless create_release

    archive_zip_path = File.join(PROJECT_ROOT_FOLDER, 'WordPress.xarchive.zip')
    zip(path: lane_context[SharedValues::XCODEBUILD_ARCHIVE], output_path: archive_zip_path)

    build_code = build_code_current
    release_version = release_version_current

    version = beta_release ? build_code : release_version
    release_url = create_github_release(
      repository: GITHUB_REPO,
      version: version,
      release_notes_file_path: WORDPRESS_RELEASE_NOTES_PATH,
      release_assets: archive_zip_path.to_s,
      prerelease: beta_release, # Beta = prerelease, Final = normal Release
      is_draft: !beta_release # Beta = publish immediately, Final = Draft (only publish after Apple approval)
    )

    send_slack_message(
      message: <<~MSG
        :wpicon-blue: :applelogo: WordPress iOS `#{release_version} (#{build_code})` is available for testing and [a GitHub release draft](#{release_url}) has been created.
      MSG
    )

    FileUtils.rm_rf(archive_zip_path)
  end

  # Builds the Jetpack app and uploads it to TestFlight, for beta-testing or final release
  #
  # @called_by CI
  #
  desc 'Builds and uploads Jetpack to TestFlight for distribution'
  lane :build_and_upload_jetpack_for_app_store do
    sentry_check_cli_installed

    update_certs_and_profiles_jetpack_app_store

    build_app(
      scheme: 'Jetpack',
      workspace: WORKSPACE_PATH,
      clean: true,
      export_team_id: EXTERNAL_TEAM_ID,
      output_directory: BUILD_PRODUCTS_PATH,
      output_name: APP_STORE_CONNECT_BUILD_NAME_JETPACK,
      derived_data_path: DERIVED_DATA_PATH,
      export_options: { **COMMON_EXPORT_OPTIONS, method: 'app-store' }
    )

    upload_build_to_testflight(
      ipa_path: lane_context[SharedValues::IPA_OUTPUT_PATH],
      whats_new_path: JETPACK_RELEASE_NOTES_PATH,
      distribution_groups: ['Beta Testers'],
      beta_app_description_path: JETPACK_BETA_APP_DESCRIPTION_PATH
    )

    sentry_debug_files_upload(
      auth_token: get_required_env('SENTRY_AUTH_TOKEN'),
      org_slug: SENTRY_ORG_SLUG,
      project_slug: SENTRY_PROJECT_SLUG_JETPACK,
      path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
    )

    release_version = release_version_current
    build_code = build_code_current

    upload_gutenberg_sourcemaps(
      sentry_project_slug: SENTRY_PROJECT_SLUG_JETPACK,
      release_version: release_version,
      build_version: build_code,
      app_identifier: JETPACK_BUNDLE_IDENTIFIER
    )

    send_slack_message(
      message: <<~MSG
        :jetpack: :applelogo: Jetpack iOS `#{release_version} (#{build_code})` is available for testing.
      MSG
    )
  end

  lane :build_for_app_store_connect_reader do |build_number: ENV.fetch('BUILDKITE_BUILD_NUMBER', nil)|
    UI.user_error!('No build number provided and BUILDKITE_BUILD_NUMBER environment variable is not set') if build_number.nil?

    sentry_check_cli_installed

    update_certs_and_profiles_app_store_reader

    build_app(
      scheme: 'Reader',
      workspace: WORKSPACE_PATH,
      clean: true,
      export_team_id: EXTERNAL_TEAM_ID,
      output_directory: BUILD_PRODUCTS_PATH,
      output_name: APP_STORE_CONNECT_BUILD_NAME_READER,
      derived_data_path: DERIVED_DATA_PATH,
      xcargs: { VERSION_LONG: build_number, VERSION_SHORT: '0.0' }.compact,
      export_options: { **COMMON_EXPORT_OPTIONS, method: 'app-store' }
    )
  end

  lane :upload_to_app_store_connect_reader do
    # Eventually, this will be replaced with a real release notes file. Or maybe not.
    temp_release_notes = File.join(Dir.tmpdir, 'reader_release_notes.md')

    begin
      File.write(temp_release_notes, 'Thank you for testing the new Reader app. Please get in touch with any feedback or suggestions.')

      upload_build_to_testflight(
        ipa_path: File.join(BUILD_PRODUCTS_PATH, "#{APP_STORE_CONNECT_BUILD_NAME_READER}.ipa"),
        whats_new_path: temp_release_notes,
        # The action fails with "Cannot add internal group to a build," despite the build having been added to the internal group.
        #
        # Groups are required when distributing to external testers, but maybe they are not when it's only internal?
        # distribution_groups: ['Internal Automattic Testers Automatic Distribution'],
        distribution_groups: [],
        beta_app_description_path: BETA_APP_DESCRIPTION_PATH_READER
      )
    ensure
      FileUtils.rm_rf(temp_release_notes)
    end
  end

  # Builds a single app and uploads it to TestFlight for *internal* testers,
  # stamping the build code with the Buildkite build number.
  #
  # The marketing version (`VERSION_SHORT`) is resolved from App Store Connect at
  # build time by `testflight_marketing_version` — the open (editable) version if
  # there is one, otherwise the next version after the newest released/approved one.
  # This keeps trunk off a marketing version App Store Connect has already approved
  # and locked (error 90062), without depending on the checked-in `VERSION_SHORT`.
  # The build code is `<marketing version>.0.<buildkite build number>` (e.g.
  # `27.3.0.4567`). Buildkite build numbers increase monotonically, so each build
  # for a given marketing version gets a unique, higher build code.
  #
  # @param [String] app One of `wordpress`, `jetpack`, or `reader`.
  #
  # @called_by CI
  #
  desc 'Builds one app and uploads it to TestFlight for internal testers'
  lane :build_and_upload_app_for_testflight do |app:|
    # Resolve everything the build code depends on — the Buildkite build number and the
    # marketing version — before any cert/profile work, so a resolution failure fails
    # fast instead of after provisioning. This lane only runs on CI.
    build_number = ENV.fetch('BUILDKITE_BUILD_NUMBER', nil)
    UI.user_error!('BUILDKITE_BUILD_NUMBER is not set — this lane is meant to run on CI') if build_number.nil?

    app = app.to_s.downcase

    case app
    when 'wordpress'
      scheme = 'WordPress'
      output_name = APP_STORE_CONNECT_BUILD_NAME_WORDPRESS
      beta_app_description_path = WORDPRESS_BETA_APP_DESCRIPTION_PATH
      sentry_project_slug = SENTRY_PROJECT_SLUG_WORDPRESS
      app_identifier = WORDPRESS_BUNDLE_IDENTIFIER
    when 'jetpack'
      scheme = 'Jetpack'
      output_name = APP_STORE_CONNECT_BUILD_NAME_JETPACK
      beta_app_description_path = JETPACK_BETA_APP_DESCRIPTION_PATH
      sentry_project_slug = SENTRY_PROJECT_SLUG_JETPACK
      app_identifier = JETPACK_BUNDLE_IDENTIFIER
    when 'reader'
      scheme = 'Reader'
      output_name = APP_STORE_CONNECT_BUILD_NAME_READER
      beta_app_description_path = BETA_APP_DESCRIPTION_PATH_READER
      sentry_project_slug = nil # Reader does not have a Sentry project yet
      app_identifier = nil
    else
      UI.user_error!("Unknown app '#{app}'. Expected one of: wordpress, jetpack, reader")
    end

    # Resolve the marketing version from App Store Connect so we never re-upload a
    # version it has already approved. WordPress and Jetpack ship in lockstep and share a
    # build code (see promote.rb / docs/testflight-promotion.md), so resolve the version
    # JOINTLY across both apps rather than from each app's own state alone — otherwise
    # Apple approving one before the other would drift their build codes apart and break
    # promotion. Reader has no App Store Connect app wired up yet (nil identifier), so it
    # falls back to the checked-in version.
    marketing_version =
      if app_identifier.nil?
        release_version_current
      else
        shared_testflight_marketing_version(app_identifiers: [WORDPRESS_BUNDLE_IDENTIFIER, JETPACK_BUNDLE_IDENTIFIER])
      end
    build_code = "#{marketing_version}.0.#{build_number}"
    UI.important("Building #{scheme} #{marketing_version} (#{build_code}) for internal TestFlight distribution")

    # Provision signing assets only once the version resolves (see the fail-fast note above).
    case app
    when 'wordpress' then update_certs_and_profiles_wordpress_app_store
    when 'jetpack' then update_certs_and_profiles_jetpack_app_store
    when 'reader' then update_certs_and_profiles_app_store_reader
    end

    sentry_check_cli_installed

    build_app(
      scheme: scheme,
      workspace: WORKSPACE_PATH,
      clean: true,
      output_directory: BUILD_PRODUCTS_PATH,
      output_name: output_name,
      derived_data_path: DERIVED_DATA_PATH,
      export_team_id: EXTERNAL_TEAM_ID,
      xcargs: { VERSION_SHORT: marketing_version, VERSION_LONG: build_code },
      export_options: { **COMMON_EXPORT_OPTIONS, method: 'app-store' }
    )

    upload_app_to_testflight_internal(
      ipa_path: lane_context[SharedValues::IPA_OUTPUT_PATH],
      beta_app_description_path: beta_app_description_path
    )

    # Upload symbols so crashes from these builds symbolicate in Sentry.
    next if sentry_project_slug.nil?

    sentry_debug_files_upload(
      auth_token: get_required_env('SENTRY_AUTH_TOKEN'),
      org_slug: SENTRY_ORG_SLUG,
      project_slug: sentry_project_slug,
      path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
    )

    upload_gutenberg_sourcemaps(
      sentry_project_slug: sentry_project_slug,
      release_version: marketing_version,
      build_version: build_code,
      app_identifier: app_identifier
    )
  end

  # Convenience wrapper that builds and uploads each app to TestFlight, one after
  # another. CI builds each app in parallel via a Buildkite matrix instead; this
  # lane is handy for running the whole set locally.
  #
  # Reader is omitted until its App Store archive is fixed (broken since #25321).
  # The per-app lane still supports `app: 'reader'`; just re-add it here once it builds.
  #
  desc 'Builds and uploads WordPress and Jetpack to TestFlight (internal)'
  lane :build_all_apps_for_testflight do
    apps = %w[wordpress jetpack]
    UI.important("Building #{apps.join(' and ')} for TestFlight. Reader is omitted because its App Store archive is currently broken.")
    apps.each do |app|
      build_and_upload_app_for_testflight(app: app)
    end
  end

  # Builds the WordPress app for a Prototype Build ("WordPress Alpha" scheme), and uploads it to Firebase App Distribution
  #
  # @called_by CI
  #
  desc 'Builds and uploads a Prototype Build'
  lane :build_and_upload_wordpress_prototype_build do
    sentry_check_cli_installed

    update_certs_and_profiles_wordpress_enterprise

    build_and_upload_prototype_build(
      scheme: 'WordPress',
      output_app_name: 'WordPress Alpha',
      firebase_app_config: FIREBASE_APP_CONFIG_WORDPRESS,
      sentry_project_slug: SENTRY_PROJECT_SLUG_WORDPRESS,
      app_identifier: 'org.wordpress.alpha'
    )
  end

  # Builds the Jetpack app for a Prototype Build ("Jetpack" scheme), and uploads it to Firebase App Distribution
  #
  # @called_by CI
  #
  desc 'Builds and uploads a Jetpack prototype build'
  lane :build_and_upload_jetpack_prototype_build do
    sentry_check_cli_installed

    update_certs_and_profiles_jetpack_enterprise

    build_and_upload_prototype_build(
      scheme: 'Jetpack',
      output_app_name: 'Jetpack Alpha',
      firebase_app_config: FIREBASE_APP_CONFIG_JETPACK,
      sentry_project_slug: SENTRY_PROJECT_SLUG_JETPACK,
      app_identifier: 'com.jetpack.alpha'
    )
  end

  lane :resolve_packages do |derived_data_path: DERIVED_DATA_PATH|
    sh(
      'xcodebuild',
      '-resolvePackageDependencies',
      '-onlyUsePackageVersionsFromResolvedFile',
      '-workspace', File.join(PROJECT_ROOT_FOLDER, 'WordPress.xcworkspace'),
      '-scheme', 'WordPress',
      '-derivedDataPath', derived_data_path
    )
  end

  #################################################
  # Helper Functions
  #################################################

  # Builds a Prototype Build for WordPress or Jetpack, then uploads it to Firebase App Distribution and comment with a link to it on the PR.
  #
  def build_and_upload_prototype_build(scheme:, output_app_name:, firebase_app_config:, sentry_project_slug:, app_identifier:)
    build_number = ENV.fetch('BUILDKITE_BUILD_NUMBER', '0')
    pr_or_branch = pull_request_number&.then { |num| "PR ##{num}" } || ENV.fetch('BUILDKITE_BRANCH', nil)

    # Build
    build_app(
      scheme: scheme,
      workspace: WORKSPACE_PATH,
      configuration: PROTOTYPE_BUILD_XCODE_CONFIGURATION,
      clean: true,
      xcargs: { VERSION_LONG: build_number, VERSION_SHORT: pr_or_branch }.compact,
      output_directory: BUILD_PRODUCTS_PATH,
      output_name: output_app_name,
      derived_data_path: DERIVED_DATA_PATH,
      export_team_id: INTERNAL_TEAM_ID,
      export_method: 'enterprise',
      export_options: { **COMMON_EXPORT_OPTIONS, method: 'enterprise' }
    )

    upload_build_to_firebase_app_distribution(
      firebase_app_config: firebase_app_config
    )

    # Upload dSYMs to Sentry
    sentry_debug_files_upload(
      auth_token: get_required_env('SENTRY_AUTH_TOKEN'),
      org_slug: SENTRY_ORG_SLUG,
      project_slug: sentry_project_slug,
      path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
    )

    upload_gutenberg_sourcemaps(
      sentry_project_slug: sentry_project_slug,
      release_version: release_version_current,
      build_version: build_number,
      app_identifier: app_identifier
    )
  end

  # The marketing version to stamp on WordPress AND Jetpack. They ship in lockstep and
  # share a build code (promote.rb distributes one build code to both — see
  # docs/testflight-promotion.md), but they're separate App Store Connect records Apple
  # can approve minutes-to-days apart. Resolving from each app's own state alone would
  # drift their build codes during that skew and break promotion; instead resolve BOTH
  # and take the higher. The max is >= each app's own 90062-safe version (so it's still
  # safe to upload for both) and identical across the two matrix jobs, so WordPress and
  # Jetpack always stamp the same version.
  #
  # @param [Array<String>] app_identifiers The bundle identifiers that share a build code.
  # @return [String] The marketing version to stamp on every one of them (e.g. "27.3").
  def shared_testflight_marketing_version(app_identifiers:)
    app_identifiers
      .map { |identifier| testflight_marketing_version(app_identifier: identifier) }
      .max_by { |version| Gem::Version.new(version) }
  end

  # Resolves the marketing version (`CFBundleShortVersionString`) for a per-commit
  # TestFlight build from live App Store Connect state, so trunk never re-uploads a
  # version App Store Connect has already approved.
  #
  # App Store Connect locks a marketing version once a build for it has been
  # *approved*: every later upload must use a strictly higher version or it's
  # rejected with error 90062 — regardless of build code. Trunk shares its version
  # with the release in flight, so the moment that release is approved every trunk
  # upload fails. Rather than trust the checked-in `VERSION_SHORT`, resolve it here:
  #
  #   • If there's an open (editable, pre-approval) App Store version newer than the
  #     latest approved one, build into it — trunk keeps flowing to the version being
  #     prepared. Hotfix versions are ignored (see `open_app_store_version`).
  #   • Otherwise the newest version is released or awaiting release, so start the
  #     next one. `next_release_version` bumps the minor and wraps 27.9 → 28.0.
  #
  # Resolves ONE app's version. WordPress and Jetpack must never drift apart, so the lane
  # combines both apps' results via `shared_testflight_marketing_version` rather than
  # calling this per app in isolation.
  #
  # @param [String] app_identifier The app's bundle identifier.
  # @return [String] The marketing version to stamp on the build (e.g. "27.3").
  def testflight_marketing_version(app_identifier:)
    resolve_testflight_marketing_version(app_identifier: app_identifier)
  rescue FastlaneCore::Interface::FastlaneError
    # Our own (and the toolkit's) UI.user_error! messages are already actionable — don't
    # re-wrap them as a generic App Store Connect failure.
    raise
  rescue ArgumentError => e
    UI.user_error!("App Store Connect returned a non-numeric marketing version for #{app_identifier} (#{e.message}); cannot resolve a TestFlight marketing version.")
  rescue StandardError => e
    UI.user_error!("Could not reach App Store Connect to resolve a TestFlight marketing version for #{app_identifier}: #{e.message}")
  end

  def resolve_testflight_marketing_version(app_identifier:)
    app = app_store_connect_app(app_identifier)
    open_version = open_app_store_version(app)
    locked_version = locked_app_store_version(app)

    if open_clears_locked?(open_version, locked_version)
      UI.message("#{app_identifier}: building into open App Store version #{open_version.version_string} (#{open_version.app_version_state})")
      return open_version.version_string
    end

    UI.user_error!("No live or pending App Store version found for #{app_identifier}; cannot resolve a TestFlight marketing version") if locked_version.nil?

    next_version = increment_release_version(locked_version.version_string)
    UI.message("#{app_identifier}: no usable open App Store version — incrementing #{locked_version.version_string} → #{next_version}")
    next_version
  end

  # True when there is an open (pre-approval) version strictly newer than everything
  # App Store Connect has already locked (live or pending release) — the only case where
  # building into `open` can't re-upload an already-approved version. ASC won't hold an
  # editable version at or below the live one, so this normally always holds; asserting
  # it here makes "never re-upload an approved version" true by construction.
  def open_clears_locked?(open_version, locked_version)
    return false if open_version.nil?
    return true if locked_version.nil?

    Gem::Version.new(open_version.version_string) > Gem::Version.new(locked_version.version_string)
  end

  # The next marketing version after `version_string`; bumps the minor and wraps
  # 27.9 → 28.0 (e.g. "27.2" or the hotfix "27.2.1" → "27.3").
  def increment_release_version(version_string)
    VERSION_FORMATTER.release_version(
      VERSION_CALCULATOR.next_release_version(version: VERSION_FORMATTER.parse(version_string))
    )
  end

  # The newest version App Store Connect hasn't approved yet — in preparation,
  # rejected, or under review — or nil. Trunk builds flow into it, matching the
  # release currently being prepared, and none of these states trip 90062.
  # `get_edit_app_store_version` deliberately excludes `IN_REVIEW`, so it's checked
  # separately or we'd bump the version out from under a release that's in review.
  #
  # Hotfix versions (patch > 0, e.g. `27.2.1`) are ignored: a hotfix line is
  # orthogonal to trunk, so trunk falls through to incrementing past the newest
  # live/pending version and builds the next feature version instead of stamping
  # itself into the hotfix's train — which would also produce a malformed five-part
  # build code like `27.2.1.0.<buildkite#>`.
  def open_app_store_version(app)
    [app.get_edit_app_store_version, app.get_in_review_app_store_version]
      .compact
      .reject { |version| VERSION_CALCULATOR.release_is_hotfix?(version: VERSION_FORMATTER.parse(version.version_string)) }
      .max_by { |version| Gem::Version.new(version.version_string) }
  end

  # The newest live or approved-and-awaiting-release version — the one App Store
  # Connect has locked, which a new upload must clear — or nil.
  def locked_app_store_version(app)
    [app.get_live_app_store_version, app.get_pending_release_app_store_version]
      .compact.max_by { |version| Gem::Version.new(version.version_string) }
  end

  def upload_build_to_testflight(ipa_path:, whats_new_path:, distribution_groups:, beta_app_description_path:)
    # Explicitly disable distributing to external testers if there are no external groups.
    distribute_external = distribution_groups.empty? == false

    upload_to_testflight(
      api_key: app_store_connect_api_key,
      ipa: ipa_path,
      beta_app_description: File.read(beta_app_description_path),
      changelog: File.read(whats_new_path),
      distribute_external: distribute_external,
      notify_external_testers: distribute_external,
      groups: distribution_groups,
      # If there is a build waiting for beta review, we ~~want~~ would like to to reject that so the new build can be submitted instead.
      reject_build_waiting_for_review: true
    )
  end

  # Uploads an already-built IPA to TestFlight for internal testers only.
  #
  # @param [String] ipa_path Path to the built IPA.
  # @param [String] beta_app_description_path Path to the beta app description file.
  #
  def upload_app_to_testflight_internal(ipa_path:, beta_app_description_path:)
    # TODO: the "what's new" text for per-commit internal builds is not
    # finalized yet. For now, generate a minimal placeholder from the commit
    # metadata so the upload has something to show. Public-beta builds will get
    # richer notes generated from the PRs merged since the previous public build.
    changelog = "Automated build from `#{ENV.fetch('BUILDKITE_BRANCH', 'unknown branch')}` (#{ENV.fetch('BUILDKITE_COMMIT', 'unknown commit')[0...7]})."

    upload_to_testflight(
      api_key: app_store_connect_api_key,
      ipa: ipa_path,
      beta_app_description: File.read(beta_app_description_path),
      changelog: changelog,
      distribute_external: false,
      notify_external_testers: false,
      # Internal builds don't participate in beta review and must not disturb an
      # existing external review submission.
      submit_beta_review: false,
      reject_build_waiting_for_review: false
    )
  end

  # Send a Slack message to the specified channel
  #
  # @param [String] message The message to send to the channel
  # @param [String] channel The Slack channel to send the message to
  #
  def send_slack_message(message:, channel: '#build-and-ship')
    slack(
      username: 'WordPress Release Bot',
      icon_url: 'https://s.w.org/style/images/about/WordPress-logotype-wmark.png',
      slack_url: get_required_env('SLACK_WEBHOOK'),
      channel: channel,
      message: message,
      default_payloads: []
    )
  end

  # Uploads a build to Firebase App Distribution and post the corresponding PR comment
  #
  # @param [Hash<Symbol, String>] firebase_app_config A hash with the app name as the key and the Firebase app ID and testers group as the value
  #   Typically one of FIREBASE_APP_CONFIG_WORDPRESS or FIREBASE_APP_CONFIG_JETPACK
  #
  def upload_build_to_firebase_app_distribution(firebase_app_config:)
    release_notes = <<~NOTES
      Pull Request: ##{pull_request_number || 'N/A'}
      Branch: `#{ENV.fetch('BUILDKITE_BRANCH', 'N/A')}`
      Commit: #{ENV.fetch('BUILDKITE_COMMIT', 'N/A')[0...7]}
    NOTES

    firebase_app_distribution(
      app: firebase_app_config[:app_id],
      service_credentials_json_data: get_required_env('FIREBASE_APP_DISTRIBUTION_ACCOUNT_KEY'),
      release_notes: release_notes,
      groups: firebase_app_config[:testers_group]
    )

    return if pull_request_number.nil?

    # PR Comment
    comment_body = prototype_build_details_comment(
      app_display_name: firebase_app_config[:app_name],
      app_icon: firebase_app_config[:app_icon],
      metadata: { Configuration: PROTOTYPE_BUILD_XCODE_CONFIGURATION },
      fold: true
    )
    comment_on_pr(
      project: GITHUB_REPO,
      pr_number: pull_request_number,
      reuse_identifier: "prototype-build-link-#{firebase_app_config[:app_id]}",
      body: comment_body
    )
  end

  def upload_gutenberg_sourcemaps(sentry_project_slug:, release_version:, build_version:, app_identifier:)
    gutenberg_bundle_source_map_folder = File.join(PROJECT_ROOT_FOLDER, 'WordPress', 'Frameworks', 'react-native-bundle-source-map')

    # To generate the full release version string to attach the source maps, we need to specify:
    # - App identifier
    # - Release version
    # - Build version
    # This conforms to the following format: <app_identifier>@<release_version>+<build_version>
    # Here are a couple of examples:
    # - Prototype build: com.jetpack.alpha@24.2+pr22654-07765b3
    # - App Store build: org.wordpress@24.1+24.1.0.3

    sentry_upload_sourcemap(
      auth_token: get_required_env('SENTRY_AUTH_TOKEN'),
      org_slug: SENTRY_ORG_SLUG,
      project_slug: sentry_project_slug,
      version: release_version,
      dist: build_version,
      build: build_version,
      app_identifier: app_identifier,
      # When the React native bundle is generated, the source map file references
      # include the local machine path, with the `rewrite` and `strip_common_prefix`
      # options Sentry automatically strips this part.
      rewrite: true,
      strip_common_prefix: true,
      sourcemap: gutenberg_bundle_source_map_folder
    )
  end
end
