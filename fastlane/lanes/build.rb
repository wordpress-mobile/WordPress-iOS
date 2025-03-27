# frozen_string_literal: true

# Sentry
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

CONCURRENT_SIMULATORS = 2

# Shared options to use when invoking `build_app` (`gym`).
#
# - `manageAppVersionAndBuildNumber: false` prevents `xcodebuild` from bumping
#   the build number when extracting an archive into an IPA file. We want to
#   use the build number we set!
COMMON_EXPORT_OPTIONS = { manageAppVersionAndBuildNumber: false }.freeze

# https://buildkite.com/docs/test-analytics/ci-environments
TEST_ANALYTICS_ENVIRONMENT = %w[
  BUILDKITE_ANALYTICS_TOKEN
  BUILDKITE_BUILD_ID
  BUILDKITE_BUILD_NUMBER
  BUILDKITE_JOB_ID
  BUILDKITE_BRANCH
  BUILDKITE_COMMIT
  BUILDKITE_MESSAGE
  BUILDKITE_BUILD_URL
].freeze

# Lanes related to Building and Testing the code
#
platform :ios do
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

    inject_buildkite_analytics_environment(xctestrun_path: xctestrun_path) if buildkite_ci?
    # Our current configuration allows for either running the Jetpack UI tests or the WordPress unit tests.
    #
    # Their scheme and xctestrun name pairing are:
    #
    # - (JetpackUITests, JetpackUITests)
    # - (WordPress, WordPressUnitTests)
    #
    # Because we only support those two modes, we can infer the scheme name from the xctestrun name
    scheme = options[:name].include?('Jetpack') ? 'JetpackUITests' : 'WordPress'

    # Only run Jetpack UI tests in parallel.
    # At the time of writing, we need to explicitly set this value despite using test plans that configure parallelism.
    parallel_testing_value = options[:name].include?('Jetpack')

    run_tests(
      workspace: WORKSPACE_PATH,
      scheme: scheme,
      device: options[:device],
      deployment_target_version: options[:ios_version],
      ensure_devices_found: true,
      test_without_building: true,
      xctestrun: xctestrun_path,
      output_directory: File.join(PROJECT_ROOT_FOLDER, 'build', 'results'),
      reset_simulator: true,
      result_bundle: true,
      output_types: '',
      fail_build: false,
      parallel_testing: parallel_testing_value,
      concurrent_workers: CONCURRENT_SIMULATORS,
      max_concurrent_simulators: CONCURRENT_SIMULATORS
    )

    trainer(path: lane_context[SharedValues::SCAN_GENERATED_XCRESULT_PATH], fail_build: true)
  end

  # Builds the WordPress app and uploads it to TestFlight, for beta-testing or final release
  #
  # @param [Boolean] skip_confirm (default: false) If true, avoids any interactive prompt
  # @param [Boolean] skip_prechecks (default: false) If true, don't run the prechecks and ios_build_preflight
  # @param [Boolean] create_release If true, creates a GitHub Release draft after the upload, with zipped xcarchive as artefact
  # @param [Boolean] beta_release If true, the GitHub release will be marked as being a pre-release
  #
  lane :build_and_upload_app_store_connect do |skip_confirm: false, skip_prechecks: false, create_release: false, beta_release: false|
    unless skip_prechecks
      ensure_git_status_clean unless is_ci
      ios_build_preflight
    end

    UI.important("Building version #{release_version_current} (#{build_code_current}) and uploading to TestFlight")
    UI.user_error!('Aborted by user request') unless skip_confirm || UI.confirm('Do you want to continue?')

    sentry_check_cli_installed

    update_certs_and_profiles_wordpress_app_store

    build_app(
      scheme: 'WordPress',
      workspace: WORKSPACE_PATH,
      clean: true,
      output_directory: BUILD_PRODUCTS_PATH,
      derived_data_path: DERIVED_DATA_PATH,
      export_team_id: get_required_env('EXT_EXPORT_TEAM_ID'),
      export_options: { **COMMON_EXPORT_OPTIONS, method: 'app-store' }
    )

    upload_build_to_testflight(
      whats_new_path: WORDPRESS_RELEASE_NOTES_PATH,
      distribution_groups: ['Internal a8c Testers', 'Public Beta Testers'],
      beta_app_description_path: WORDPRESS_BETA_APP_DESCRIPTION_PATH
    )

    sentry_upload_dsym(
      auth_token: get_required_env('SENTRY_AUTH_TOKEN'),
      org_slug: SENTRY_ORG_SLUG,
      project_slug: SENTRY_PROJECT_SLUG_WORDPRESS,
      dsym_path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
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
      export_team_id: get_required_env('EXT_EXPORT_TEAM_ID'),
      output_directory: BUILD_PRODUCTS_PATH,
      derived_data_path: DERIVED_DATA_PATH,
      export_options: { **COMMON_EXPORT_OPTIONS, method: 'app-store' }
    )

    upload_build_to_testflight(
      whats_new_path: JETPACK_RELEASE_NOTES_PATH,
      distribution_groups: ['Beta Testers'],
      beta_app_description_path: JETPACK_BETA_APP_DESCRIPTION_PATH
    )

    sentry_upload_dsym(
      auth_token: get_required_env('SENTRY_AUTH_TOKEN'),
      org_slug: SENTRY_ORG_SLUG,
      project_slug: SENTRY_PROJECT_SLUG_JETPACK,
      dsym_path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
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
      export_team_id: ENV.fetch('INT_EXPORT_TEAM_ID', nil),
      export_method: 'enterprise',
      export_options: { **COMMON_EXPORT_OPTIONS, method: 'enterprise' }
    )

    upload_build_to_firebase_app_distribution(
      firebase_app_config: firebase_app_config
    )

    # Upload dSYMs to Sentry
    sentry_upload_dsym(
      auth_token: get_required_env('SENTRY_AUTH_TOKEN'),
      org_slug: SENTRY_ORG_SLUG,
      project_slug: sentry_project_slug,
      dsym_path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
    )

    upload_gutenberg_sourcemaps(
      sentry_project_slug: sentry_project_slug,
      release_version: release_version_current,
      build_version: build_number,
      app_identifier: app_identifier
    )
  end

  def inject_buildkite_analytics_environment(xctestrun_path:)
    require 'plist'

    xctestrun = Plist.parse_xml(xctestrun_path)
    xctestrun['TestConfigurations'].each do |configuration|
      configuration['TestTargets'].each do |target|
        TEST_ANALYTICS_ENVIRONMENT.each do |key|
          value = ENV.fetch(key)
          next if value.nil?

          target['EnvironmentVariables'][key] = value
        end
      end
    end

    File.write(xctestrun_path, Plist::Emit.dump(xctestrun))
  end

  def buildkite_ci?
    ENV.fetch('BUILDKITE', false)
  end

  def upload_build_to_testflight(whats_new_path:, distribution_groups:, beta_app_description_path:)
    upload_to_testflight(
      team_id: get_required_env('FASTLANE_ITC_TEAM_ID'),
      api_key_path: APP_STORE_CONNECT_KEY_PATH,
      beta_app_description: File.read(beta_app_description_path),
      changelog: File.read(whats_new_path),
      distribute_external: true,
      groups: distribution_groups,
      # If there is a build waiting for beta review, we ~~want~~ would like to to reject that so the new build can be submitted instead.
      reject_build_waiting_for_review: true
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
