# frozen_string_literal: true

SENTRY_ORG_SLUG = 'a8c'
SENTRY_PROJECT_SLUG_WORDPRESS = 'wordpress-ios'
SENTRY_PROJECT_SLUG_JETPACK = 'jetpack-ios'
APPCENTER_OWNER_NAME = 'automattic'
APPCENTER_OWNER_TYPE = 'organization'

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
  lane :build_for_testing do |options|
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

    UI.user_error!("Unable to find .xctestrun file at #{build_products_path}") if xctestrun_path.nil? || !File.exist?((xctestrun_path))

    inject_buildkite_analytics_environment(xctestrun_path: xctestrun_path) if buildkite_ci?

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
      result_bundle: true
    )
  end

  # Builds the WordPress app and uploads it to TestFlight, for beta-testing or final release
  #
  # @option [Boolean] skip_confirm (default: false) If true, avoids any interactive prompt
  # @option [Boolean] skip_prechecks (default: false) If true, don't run the ios_build_prechecks and ios_build_preflight
  # @option [Boolean] create_release If true, creates a GitHub Release draft after the upload, with zipped xcarchive as artefact
  # @option [Boolean] beta_release If true, the GitHub release will be marked as being a pre-release
  #
  # @called_by CI
  #
  desc 'Builds and uploads for distribution to App Store Connect'
  lane :build_and_upload_app_store_connect do |options|
    ios_build_prechecks(skip_confirm: options[:skip_confirm], external: true) unless options[:skip_prechecks]
    ios_build_preflight unless options[:skip_prechecks]

    sentry_check_cli_installed
    appstore_code_signing

    gym(
      scheme: 'WordPress',
      workspace: WORKSPACE_PATH,
      clean: true,
      output_directory: BUILD_PRODUCTS_PATH,
      derived_data_path: DERIVED_DATA_PATH,
      export_team_id: get_required_env('EXT_EXPORT_TEAM_ID'),
      export_options: { method: 'app-store' }
    )

    testflight(
      skip_waiting_for_build_processing: true,
      team_id: get_required_env('FASTLANE_ITC_TEAM_ID'),
      api_key_path: APP_STORE_CONNECT_KEY_PATH
    )

    sentry_upload_dsym(
      auth_token: get_required_env('SENTRY_AUTH_TOKEN'),
      org_slug: SENTRY_ORG_SLUG,
      project_slug: SENTRY_PROJECT_SLUG_WORDPRESS,
      dsym_path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
    )

    next unless options[:create_release]

    archive_zip_path = File.join(PROJECT_ROOT_FOLDER, 'WordPress.xarchive.zip')
    zip(path: lane_context[SharedValues::XCODEBUILD_ARCHIVE], output_path: archive_zip_path)

    version = options[:beta_release] ? ios_get_build_version : ios_get_app_version
    create_release(
      repository: GHHELPER_REPO,
      version: version,
      release_notes_file_path: File.join(PROJECT_ROOT_FOLDER, 'WordPress', 'Resources', 'release_notes.txt'),
      release_assets: archive_zip_path.to_s,
      prerelease: options[:beta_release]
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
      export_options: { method: 'app-store' }
    )

    testflight(
      skip_waiting_for_build_processing: true,
      team_id: '299112',
      api_key_path: APP_STORE_CONNECT_KEY_PATH
    )

    sentry_upload_dsym(
      auth_token: get_required_env('SENTRY_AUTH_TOKEN'),
      org_slug: SENTRY_ORG_SLUG,
      project_slug: SENTRY_PROJECT_SLUG_JETPACK,
      dsym_path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
    )
  end

  # Builds the "WordPress Internal" app and uploads it to App Center
  #
  # @option [Boolean] skip_confirm (default: false) If true, avoids any interactive prompt
  # @option [Boolean] skip_prechecks (default: false) If true, don't run the ios_build_prechecks and ios_build_preflight
  #
  # @called_by CI
  #
  desc 'Builds and uploads for distribution to App Center'
  lane :build_and_upload_app_center do |options|
    ios_build_prechecks(skip_confirm: options[:skip_confirm], internal: true) unless options[:skip_prechecks]
    ios_build_preflight unless options[:skip_prechecks]

    sentry_check_cli_installed

    internal_code_signing

    gym(
      scheme: 'WordPress Internal',
      workspace: WORKSPACE_PATH,
      clean: true,
      output_directory: BUILD_PRODUCTS_PATH,
      output_name: 'WordPress Internal',
      derived_data_path: DERIVED_DATA_PATH,
      export_team_id: get_required_env('INT_EXPORT_TEAM_ID'),
      export_method: 'enterprise',
      export_options: { method: 'enterprise' }
    )

    appcenter_upload(
      api_token: get_required_env('APPCENTER_API_TOKEN'),
      owner_name: APPCENTER_OWNER_NAME,
      owner_type: APPCENTER_OWNER_TYPE,
      app_name: 'WP-Internal',
      file: lane_context[SharedValues::IPA_OUTPUT_PATH],
      dsym: lane_context[SharedValues::DSYM_OUTPUT_PATH],
      notify_testers: false
    )

    sentry_upload_dsym(
      auth_token: get_required_env('SENTRY_AUTH_TOKEN'),
      org_slug: SENTRY_ORG_SLUG,
      project_slug: SENTRY_PROJECT_SLUG_WORDPRESS,
      dsym_path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
    )
  end

  # Builds the WordPress app for an Installable Build ("WordPress Alpha" scheme), and uploads it to App Center
  #
  # @called_by CI
  #
  desc 'Builds and uploads an installable build'
  lane :build_and_upload_installable_build do
    sentry_check_cli_installed

    alpha_code_signing

    # Get the current build version, and update it if needed
    version_config_path = File.join(PROJECT_ROOT_FOLDER, 'config', 'Version.internal.xcconfig')
    versions = Xcodeproj::Config.new(File.new(version_config_path)).to_hash
    build_number = generate_installable_build_number
    UI.message("Updating build version to #{build_number}")
    versions['VERSION_LONG'] = build_number
    new_config = Xcodeproj::Config.new(versions)
    new_config.save_as(Pathname.new(version_config_path))

    gym(
      scheme: 'WordPress Alpha',
      workspace: WORKSPACE_PATH,
      clean: true,
      output_directory: BUILD_PRODUCTS_PATH,
      output_name: 'WordPress Alpha',
      derived_data_path: DERIVED_DATA_PATH,
      export_team_id: ENV.fetch('INT_EXPORT_TEAM_ID', nil),
      export_method: 'enterprise',
      export_options: { method: 'enterprise' }
    )

    appcenter_upload(
      api_token: get_required_env('APPCENTER_API_TOKEN'),
      owner_name: APPCENTER_OWNER_NAME,
      owner_type: APPCENTER_OWNER_TYPE,
      app_name: 'WPiOS-One-Offs',
      file: lane_context[SharedValues::IPA_OUTPUT_PATH],
      dsym: lane_context[SharedValues::DSYM_OUTPUT_PATH],
      destinations: 'All-users-of-WPiOS-One-Offs',
      notify_testers: false
    )

    sentry_upload_dsym(
      auth_token: get_required_env('SENTRY_AUTH_TOKEN'),
      org_slug: SENTRY_ORG_SLUG,
      project_slug: SENTRY_PROJECT_SLUG_WORDPRESS,
      dsym_path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
    )

    post_installable_build_pr_comment(app_name: 'WordPress', build_number: build_number, url_slug: 'WPiOS-One-Offs')
  end

  # Builds the Jetpack app for an Installable Build ("Jetpack" scheme), and uploads it to App Center
  #
  # @called_by CI
  #
  desc 'Builds and uploads a Jetpack installable build'
  lane :build_and_upload_jetpack_installable_build do
    sentry_check_cli_installed

    jetpack_alpha_code_signing

    # Get the current build version, and update it if needed
    version_config_path = File.join(PROJECT_ROOT_FOLDER, 'config', 'Version.internal.xcconfig')
    versions = Xcodeproj::Config.new(File.new(version_config_path)).to_hash
    build_number = generate_installable_build_number
    UI.message("Updating build version to #{build_number}")
    versions['VERSION_LONG'] = build_number
    new_config = Xcodeproj::Config.new(versions)
    new_config.save_as(Pathname.new(version_config_path))

    gym(
      scheme: 'Jetpack',
      workspace: WORKSPACE_PATH,
      configuration: 'Release-Alpha',
      clean: true,
      output_directory: BUILD_PRODUCTS_PATH,
      output_name: 'Jetpack Alpha',
      derived_data_path: DERIVED_DATA_PATH,
      export_team_id: ENV.fetch('INT_EXPORT_TEAM_ID', nil),
      export_method: 'enterprise',
      export_options: { method: 'enterprise' }
    )

    appcenter_upload(
      api_token: get_required_env('APPCENTER_API_TOKEN'),
      owner_name: APPCENTER_OWNER_NAME,
      owner_type: APPCENTER_OWNER_TYPE,
      app_name: 'jetpack-installable-builds',
      file: lane_context[SharedValues::IPA_OUTPUT_PATH],
      dsym: lane_context[SharedValues::DSYM_OUTPUT_PATH],
      destinations: 'Collaborators',
      notify_testers: false
    )

    sentry_upload_dsym(
      auth_token: get_required_env('SENTRY_AUTH_TOKEN'),
      org_slug: SENTRY_ORG_SLUG,
      project_slug: SENTRY_PROJECT_SLUG_JETPACK,
      dsym_path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
    )

    post_installable_build_pr_comment(app_name: 'Jetpack', build_number: build_number, url_slug: 'jetpack-installable-builds')
  end

  #################################################
  # Helper Functions
  #################################################


  # Generates a build number for Installable Builds, based on the PR number and short commit SHA1
  #
  # @note This function uses Buildkite-specific ENV vars
  #
  def generate_installable_build_number
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

  # Posts a comment on the current PR to inform where to download a given Installable Build that was just published to App Center.
  #
  # Use this only after `upload_to_app_center` as been called, as it announces how said App Center build can be installed.
  #
  # @param [String] app_name The display name to use in the comment text to identify which app this Installable Build is about
  # @param [String] build_number The App Center's build number for this build
  # @param [String] url_slug The last component of the `install.appcenter.ms` URL used to install the app. Typically a sluggified version of the app name in App Center (e.g. `WPiOS-One-Offs`)
  #
  # @called_by CI — especially, relies on `BUILDKITE_PULL_REQUEST` being defined
  #
  def post_installable_build_pr_comment(app_name:, build_number:, url_slug:)
    UI.message("Successfully built and uploaded installable build `#{build_number}` to App Center.")

    return if ENV['BUILDKITE_PULL_REQUEST'].nil?

    install_url = "https://install.appcenter.ms/orgs/automattic/apps/#{url_slug}/"
    qr_code_url = "https://chart.googleapis.com/chart?chs=500x500&cht=qr&chl=#{CGI.escape(install_url)}&choe=UTF-8"
    comment_body = <<~COMMENT_BODY
      You can test the changes in <strong>#{app_name}</strong> from this Pull Request by:<ul>
        <li><a href='#{install_url}'>Clicking here</a> or scanning the QR code below to access App Center</li>
        <li>Then installing the build number <code>#{build_number}</code> on your iPhone</li>
      </ul>
      <img src='#{qr_code_url}' width='150' height='150' />
      If you need access to App Center, please ask a maintainer to add you.
    COMMENT_BODY

    comment_on_pr(
      project: 'wordpress-mobile/wordpress-ios',
      pr_number: Integer(ENV.fetch('BUILDKITE_PULL_REQUEST', nil)),
      reuse_identifier: "installable-build-link--#{url_slug}",
      body: comment_body
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
end
