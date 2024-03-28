# frozen_string_literal: true

SENTRY_ORG_SLUG = 'a8c'
SENTRY_PROJECT_SLUG_WORDPRESS = 'wordpress-ios'
SENTRY_PROJECT_SLUG_JETPACK = 'jetpack-ios'
APPCENTER_OWNER_NAME = 'automattic'
APPCENTER_OWNER_TYPE = 'organization'
CONCURRENT_SIMULATORS = 2

# Shared options to use when invoking `gym` / `build_app`.
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

    inject_buildkite_analytics_environment(xctestrun_path:) if buildkite_ci?
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
      scheme:,
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
  # @option [Boolean] skip_confirm (default: false) If true, avoids any interactive prompt
  # @option [Boolean] skip_prechecks (default: false) If true, don't run the prechecks and ios_build_preflight
  # @option [Boolean] create_release If true, creates a GitHub Release draft after the upload, with zipped xcarchive as artefact
  # @option [Boolean] beta_release If true, the GitHub release will be marked as being a pre-release
  #
  # @called_by CI
  #
  desc 'Builds and uploads for distribution to App Store Connect'
  lane :build_and_upload_app_store_connect do |options|
    unless options[:skip_prechecks]
      ensure_git_status_clean unless is_ci
      ios_build_preflight
    end

    UI.important("Building version #{release_version_current} (#{build_code_current}) and uploading to TestFlight")
    UI.user_error!('Aborted by user request') unless options[:skip_confirm] || UI.confirm('Do you want to continue?')

    sentry_check_cli_installed

    appstore_code_signing

    gym(
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
      distribution_groups: ['Internal a8c Testers', 'Public Beta Testers']
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

    next unless options[:create_release]

    archive_zip_path = File.join(PROJECT_ROOT_FOLDER, 'WordPress.xarchive.zip')
    zip(path: lane_context[SharedValues::XCODEBUILD_ARCHIVE], output_path: archive_zip_path)

    build_code = build_code_current
    release_version = release_version_current

    version = options[:beta_release] ? build_code : release_version
    release_url = create_release(
      repository: GITHUB_REPO,
      version:,
      release_notes_file_path: WORDPRESS_RELEASE_NOTES_PATH,
      release_assets: archive_zip_path.to_s,
      prerelease: options[:beta_release]
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

    jetpack_appstore_code_signing

    gym(
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
      distribution_groups: ['Beta Testers']
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
      release_version:,
      build_version: build_code,
      app_identifier: JETPACK_BUNDLE_IDENTIFIER
    )

    send_slack_message(
      message: <<~MSG
        :jetpack: :applelogo: Jetpack iOS `#{release_version} (#{build_code})` is available for testing.
      MSG
    )
  end

  # Builds the WordPress app for a Prototype Build ("WordPress Alpha" scheme), and uploads it to App Center
  #
  # @called_by CI
  #
  desc 'Builds and uploads a Prototype Build'
  lane :build_and_upload_wordpress_prototype_build do
    sentry_check_cli_installed

    alpha_code_signing

    build_and_upload_prototype_build(
      scheme: 'WordPress Alpha',
      output_app_name: 'WordPress Alpha',
      appcenter_app_name: 'WPiOS-One-Offs',
      app_icon: ':wordpress:', # Use Buildkite emoji
      sentry_project_slug: SENTRY_PROJECT_SLUG_WORDPRESS,
      app_identifier: 'org.wordpress.alpha'
    )
  end

  # Builds the Jetpack app for a Prototype Build ("Jetpack" scheme), and uploads it to App Center
  #
  # @called_by CI
  #
  desc 'Builds and uploads a Jetpack prototype build'
  lane :build_and_upload_jetpack_prototype_build do
    sentry_check_cli_installed

    jetpack_alpha_code_signing

    build_and_upload_prototype_build(
      scheme: 'Jetpack',
      output_app_name: 'Jetpack Alpha',
      appcenter_app_name: 'jetpack-installable-builds',
      app_icon: ':jetpack:', # Use Buildkite emoji
      sentry_project_slug: SENTRY_PROJECT_SLUG_JETPACK,
      app_identifier: 'com.jetpack.alpha'
    )
  end

  #################################################
  # Helper Functions
  #################################################


  # Generates a build number for Prototype Builds, based on the PR number and short commit SHA1
  #
  # @note This function uses Buildkite-specific ENV vars
  #
  def generate_prototype_build_number
    if ENV['BUILDKITE']
      commit = ENV.fetch('BUILDKITE_COMMIT', nil)[0, 7]
      branch = ENV.fetch('BUILDKITE_BRANCH', nil)
      pr_num = ENV.fetch('BUILDKITE_PULL_REQUEST', nil)

      pr_num == 'false' ? "#{branch}-#{commit}" : "pr#{pr_num}-#{commit}"
    else
      repo = Git.open(PROJECT_ROOT_FOLDER)
      commit = repo.current_branch
      branch = repo.revparse('HEAD')[0, 7]

      "#{branch}-#{commit}"
    end
  end

  # Builds a Prototype Build for WordPress or Jetpack, then uploads it to App Center and comment with a link to it on the PR.
  #
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/ParameterLists
  def build_and_upload_prototype_build(scheme:, output_app_name:, appcenter_app_name:, app_icon:, sentry_project_slug:, app_identifier:)
    configuration = 'Release-Alpha'

    # Get the current build version, and update it if needed
    version_config_path = File.join(PROJECT_ROOT_FOLDER, 'config', 'Version.internal.xcconfig')
    versions = Xcodeproj::Config.new(File.new(version_config_path)).to_hash
    build_number = generate_prototype_build_number
    UI.message("Updating build version to #{build_number}")
    versions['VERSION_LONG'] = build_number
    new_config = Xcodeproj::Config.new(versions)
    new_config.save_as(Pathname.new(version_config_path))

    # Build
    gym(
      scheme:,
      workspace: WORKSPACE_PATH,
      configuration:,
      clean: true,
      output_directory: BUILD_PRODUCTS_PATH,
      output_name: output_app_name,
      derived_data_path: DERIVED_DATA_PATH,
      export_team_id: ENV.fetch('INT_EXPORT_TEAM_ID', nil),
      export_method: 'enterprise',
      export_options: { **COMMON_EXPORT_OPTIONS, method: 'enterprise' }
    )

    # Upload to App Center
    commit = ENV.fetch('BUILDKITE_COMMIT', 'Unknown')
    pr = ENV.fetch('BUILDKITE_PULL_REQUEST', nil)
    release_notes = <<~NOTES
      - Branch: `#{ENV.fetch('BUILDKITE_BRANCH', 'Unknown')}`\n
      - Commit: [#{commit[0...7]}](https://github.com/#{GITHUB_REPO}/commit/#{commit})\n
      - Pull Request: [##{pr}](https://github.com/#{GITHUB_REPO}/pull/#{pr})\n
    NOTES

    upload_build_to_app_center(
      name: appcenter_app_name,
      file: lane_context[SharedValues::IPA_OUTPUT_PATH],
      dsym: lane_context[SharedValues::DSYM_OUTPUT_PATH],
      release_notes:,
      distribute_to_everyone: false
    )

    # Upload dSYMs to Sentry
    sentry_upload_dsym(
      auth_token: get_required_env('SENTRY_AUTH_TOKEN'),
      org_slug: SENTRY_ORG_SLUG,
      project_slug: sentry_project_slug,
      dsym_path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
    )

    upload_gutenberg_sourcemaps(
      sentry_project_slug:,
      release_version: release_version_current,
      build_version: build_number,
      app_identifier:
    )

    # Post PR Comment
    comment_body = prototype_build_details_comment(
      app_display_name: output_app_name,
      app_icon:,
      app_center_org_name: APPCENTER_OWNER_NAME,
      metadata: { Configuration: configuration },
      fold: true
    )

    comment_on_pr(
      project: GITHUB_REPO,
      pr_number: Integer(ENV.fetch('BUILDKITE_PULL_REQUEST', nil)),
      reuse_identifier: "prototype-build-link-#{appcenter_app_name}",
      body: comment_body
    )

    # Attach version information as Buildkite metadata and annotation
    appcenter_id = lane_context.dig(SharedValues::APPCENTER_BUILD_INFORMATION, 'id')
    metadata = versions.merge(build_type: 'Prototype', 'appcenter:id': appcenter_id)
    buildkite_metadata(set: metadata)
    appcenter_install_url = "https://install.appcenter.ms/orgs/#{APPCENTER_OWNER_NAME}/apps/#{appcenter_app_name}/releases/#{appcenter_id}"
    list = metadata.map { |k, v| " - **#{k}**: #{v}" }.join("\n")
    buildkite_annotate(context: "appcenter-info-#{output_app_name}", style: 'info', message: "#{output_app_name} [App Center Build](#{appcenter_install_url}) Info:\n\n#{list}")
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/ParameterLists

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

  def upload_build_to_testflight(whats_new_path:, distribution_groups:)
    upload_to_testflight(
      team_id: get_required_env('FASTLANE_ITC_TEAM_ID'),
      api_key_path: APP_STORE_CONNECT_KEY_PATH,
      changelog: File.read(whats_new_path),
      distribute_external: true,
      groups: distribution_groups,
      # If there is a build waiting for beta review, we want to reject that so the new build can be submitted instead
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
      channel:,
      message:,
      default_payloads: []
    )
  end

  def upload_build_to_app_center(
    name:,
    file:,
    dsym:,
    release_notes:,
    distribute_to_everyone:
  )
    appcenter_upload(
      api_token: get_required_env('APPCENTER_API_TOKEN'),
      owner_name: APPCENTER_OWNER_NAME,
      owner_type: APPCENTER_OWNER_TYPE,
      app_name: name,
      file:,
      dsym:,
      release_notes:,
      destinations: distribute_to_everyone ? '*' : 'Collaborators',
      notify_testers: false
    )
  end

  def upload_gutenberg_sourcemaps(sentry_project_slug:, release_version:, build_version:, app_identifier:)
    gutenberg_bundle_source_map_folder = File.join(PROJECT_ROOT_FOLDER, 'Pods', 'Gutenberg', 'react-native-bundle-source-map')

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
      app_identifier:,
      # When the React native bundle is generated, the source map file references
      # include the local machine path, with the `rewrite` and `strip_common_prefix`
      # options Sentry automatically strips this part.
      rewrite: true,
      strip_common_prefix: true,
      sourcemap: gutenberg_bundle_source_map_folder
    )
  end
end
