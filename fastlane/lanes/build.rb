# frozen_string_literal: true

#####################################################################################
# test_without_building
# -----------------------------------------------------------------------------------
# This lane runs tests without building the app.
# It requires a prebuilt xctestrun file and simulator destination where the tests will be run.
# -----------------------------------------------------------------------------------
# Usage:
# bundle exec fastlane test_without_building [name:<Partial name of the .xctestrun file>]
#
# Example:
# bundle exec fastlane test_without_building name:UITests
#####################################################################################
desc 'Run tests without building'
lane :test_without_building do |options|
  # Find the referenced .xctestrun file based on its name
  build_products_path = File.join(DERIVED_DATA_PATH, 'Build', 'Products')

  test_plan_path = Dir.glob(File.join(build_products_path, '*.xctestrun')).select do |e|
    e.include?(options[:name])
  end.first

  unless !test_plan_path.nil? && File.exist?((test_plan_path))
    UI.user_error!("Unable to find .xctestrun file at #{build_products_path}")
  end

  run_tests(
    workspace: WORKSPACE_PATH,
    scheme: 'WordPress',
    device: options[:device],
    deployment_target_version: options[:ios_version],
    ensure_devices_found: true,
    test_without_building: true,
    xctestrun: test_plan_path,
    output_directory: File.join(PROJECT_ROOT_FOLDER, 'build', 'results'),
    reset_simulator: true,
    result_bundle: true
  )
end

#####################################################################################
# build_and_upload_app_store_connect
# -----------------------------------------------------------------------------------
# This lane builds the app and uploads it for App Store Connect
# -----------------------------------------------------------------------------------
# Usage:
# bundle exec fastlane build_and_upload_app_store_connect [skip_confirm:<skip confirm>]
#  [create_gh_release:<create release on GH>] [beta_release:<is a beta release>]
#
# Example:
# bundle exec fastlane build_and_upload_app_store_connect
# bundle exec fastlane build_and_upload_app_store_connect skip_confirm:true
# bundle exec fastlane build_and_upload_app_store_connect create_gh_release:true
# bundle exec fastlane build_and_upload_app_store_connect beta_release:true
#####################################################################################
desc 'Builds and uploads for distribution to App Store Connect'
lane :build_and_upload_app_store_connect do |options|
  ios_build_prechecks(
    skip_confirm: options[:skip_confirm],
    internal: options[:beta_release],
    external: true
  )

  ios_build_preflight

  build_and_upload_itc(
    skip_prechecks: true,
    skip_confirm: options[:skip_confirm],
    beta_release: options[:beta_release],
    create_release: options[:create_gh_release]
  )

end

#####################################################################################
# build_and_upload_app_center
# -----------------------------------------------------------------------------------
# This lane builds the app and uploads it for App Center
# -----------------------------------------------------------------------------------
# Usage:
# bundle exec fastlane build_and_upload_app_center [skip_confirm:<skip confirm>]
#
# Example:
# bundle exec fastlane build_and_upload_app_center
# bundle exec fastlane build_and_upload_app_center skip_confirm:true
#####################################################################################
desc 'Builds and uploads for distribution to App Center'
lane :build_and_upload_app_center do |options|
  ios_build_prechecks(
    skip_confirm: options[:skip_confirm],
    internal: true,
    external: true
  )

  ios_build_preflight

  build_and_upload_internal(
    skip_prechecks: true,
    skip_confirm: options[:skip_confirm]
  )
end

#####################################################################################
# build_and_upload_installable_build
# -----------------------------------------------------------------------------------
# This lane builds the app and upload it for adhoc testing
# -----------------------------------------------------------------------------------
# Usage:
# bundle exec fastlane build_and_upload_installable_build [version_long:<version_long>]
#
# Example:
# bundle exec fastlane build_and_upload_installable_build
# bundle exec fastlane build_and_upload_installable_build build_number:123
#####################################################################################
desc 'Builds and uploads an installable build'
lane :build_and_upload_installable_build do |options|
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
    export_method: 'enterprise',
    clean: true,
    output_directory: BUILD_PRODUCTS_PATH,
    output_name: 'WordPress Alpha',
    derived_data_path: DERIVED_DATA_PATH,
    export_team_id: ENV['INT_EXPORT_TEAM_ID'],
    export_options: { method: 'enterprise' }
  )

  appcenter_upload(
    api_token: get_required_env('APPCENTER_API_TOKEN'),
    owner_name: 'automattic',
    owner_type: 'organization',
    app_name: 'WPiOS-One-Offs',
    file: lane_context[SharedValues::IPA_OUTPUT_PATH],
    dsym: lane_context[SharedValues::DSYM_OUTPUT_PATH],
    destinations: 'All-users-of-WPiOS-One-Offs',
    notify_testers: false
  )

  sentry_upload_dsym(
    auth_token: get_required_env('SENTRY_AUTH_TOKEN'),
    org_slug: 'a8c',
    project_slug: 'wordpress-ios',
    dsym_path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
  )

  return if ENV['BUILDKITE_PULL_REQUEST'].nil?

  download_url = Actions.lane_context[SharedValues::APPCENTER_DOWNLOAD_LINK]
  UI.message("Successfully built and uploaded installable build here: #{download_url}")
  install_url = 'https://install.appcenter.ms/orgs/automattic/apps/WPiOS-One-Offs/'

  comment_body = "You can test the <strong>WordPress</strong> changes on this Pull Request by downloading it from AppCenter <a href='#{install_url}'>here</a> with build number: <code>#{build_number}</code>. IPA is available <a href='#{download_url}'>here</a>. If you need access to this, you can ask a maintainer to add you."

  comment_on_pr(
    project: 'wordpress-mobile/wordpress-ios',
    pr_number: Integer(ENV['BUILDKITE_PULL_REQUEST']),
    reuse_identifier: 'installable-build-link',
    body: comment_body
  )
end

#####################################################################################
# build_and_upload_installable_build
# -----------------------------------------------------------------------------------
# This lane builds the app and upload it for adhoc testing
# -----------------------------------------------------------------------------------
# Usage:
# bundle exec fastlane build_and_upload_installable_build [version_long:<version_long>]
#
# Example:
# bundle exec fastlane build_and_upload_installable_build
# bundle exec fastlane build_and_upload_installable_build build_number:123
#####################################################################################
desc "Builds and uploads a Jetpack installable build"
lane :build_and_upload_jetpack_installable_build do | options |
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
    scheme: "Jetpack",
    workspace: WORKSPACE_PATH,
    export_method: "enterprise",
    configuration: "Release-Alpha",
    clean: true,
    output_directory: BUILD_PRODUCTS_PATH,
    output_name: "Jetpack Alpha",
    derived_data_path: DERIVED_DATA_PATH,
    export_team_id: ENV["INT_EXPORT_TEAM_ID"],
    export_options: { method: "enterprise" }
  )

  appcenter_upload(
    api_token: get_required_env("APPCENTER_API_TOKEN"),
    owner_name: "automattic",
    owner_type: "organization",
    app_name: "jetpack-installable-builds",
    file: lane_context[SharedValues::IPA_OUTPUT_PATH],
    dsym: lane_context[SharedValues::DSYM_OUTPUT_PATH],
    destinations: "Collaborators",
    notify_testers: false
  )

  sentry_upload_dsym(
    auth_token: get_required_env("SENTRY_AUTH_TOKEN"),
    org_slug: 'a8c',
    project_slug: 'jetpack-ios',
    dsym_path: lane_context[SharedValues::DSYM_OUTPUT_PATH],
  )

  return if ENV['BUILDKITE_PULL_REQUEST'].nil?

  download_url = Actions.lane_context[SharedValues::APPCENTER_DOWNLOAD_LINK]
  UI.message("Successfully built and uploaded installable build here: #{download_url}")
  install_url = 'https://install.appcenter.ms/orgs/automattic/apps/jetpack-installable-builds/'

  comment_body = "You can test the <strong>Jetpack</strong> changes on this Pull Request by downloading it from AppCenter <a href='#{install_url}'>here</a> with build number: <code>#{build_number}</code>. IPA is available <a href='#{download_url}'>here</a>. If you need access to this, you can ask a maintainer to add you."

  comment_on_pr(
    project: 'wordpress-mobile/wordpress-ios',
    pr_number: Integer(ENV['BUILDKITE_PULL_REQUEST']),
    reuse_identifier: 'jetpack-installable-build-link',
    body: comment_body
  )
end

#####################################################################################
# build_and_upload_internal
# -----------------------------------------------------------------------------------
# This lane builds the app and upload it for internal testing
# -----------------------------------------------------------------------------------
# Usage:
# bundle exec fastlane build_and_upload_internal [skip_confirm:<skip confirm>]
#
# Example:
# bundle exec fastlane build_and_upload_internal
# bundle exec fastlane build_and_upload_internal skip_confirm:true
#####################################################################################
desc 'Builds and uploads for distribution'
lane :build_and_upload_internal do |options|
  ios_build_prechecks(skip_confirm: options[:skip_confirm], internal: true) unless options[:skip_prechecks]
  ios_build_preflight unless options[:skip_prechecks]

  sentry_check_cli_installed

  internal_code_signing

  gym(
    scheme: 'WordPress Internal',
    workspace: WORKSPACE_PATH,
    export_method: 'enterprise',
    clean: true,
    output_directory: BUILD_PRODUCTS_PATH,
    output_name: 'WordPress Internal',
    derived_data_path: DERIVED_DATA_PATH,
    export_team_id: get_required_env('INT_EXPORT_TEAM_ID'),
    export_options: { method: 'enterprise' }
  )

  appcenter_upload(
    api_token: ENV['APPCENTER_API_TOKEN'],
    owner_name: 'automattic',
    owner_type: 'organization',
    app_name: 'WP-Internal',
    file: lane_context[SharedValues::IPA_OUTPUT_PATH],
    dsym: lane_context[SharedValues::DSYM_OUTPUT_PATH],
    notify_testers: false
  )

  sentry_upload_dsym(
    auth_token: get_required_env('SENTRY_AUTH_TOKEN'),
    org_slug: 'a8c',
    project_slug: 'wordpress-ios',
    dsym_path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
  )
end

#####################################################################################
# build_and_upload_itc
# -----------------------------------------------------------------------------------
# This lane builds the app and upload it for external distribution
# -----------------------------------------------------------------------------------
# Usage:
# bundle exec fastlane build_and_upload_itc [skip_confirm:<skip confirm>] [create_release:<Create release on GH>] [beta_release:<intermediate beta?>]
#
# Example:
# bundle exec fastlane build_and_upload_itc
# bundle exec fastlane build_and_upload_itc skip_confirm:true
# bundle exec fastlane build_and_upload_itc create_release:true
# bundle exec fastlane build_and_upload_itc create_release:true beta_release:true
#####################################################################################
desc 'Builds and uploads for distribution'
lane :build_and_upload_itc do |options|
  ios_build_prechecks(skip_confirm: options[:skip_confirm], external: true) unless options[:skip_prechecks]
  ios_build_preflight unless options[:skip_prechecks]

  sentry_check_cli_installed
  appstore_code_signing

  gym(
    scheme: 'WordPress',
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
    org_slug: 'a8c',
    project_slug: 'wordpress-ios',
    dsym_path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
  )

  if options[:create_release]
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
end

desc "Build Jetpack for TestFlight"
lane :build_and_upload_jetpack_for_app_store do |options|

  jetpack_appstore_code_signing

  gym(
    scheme: "Jetpack",
    workspace: WORKSPACE_PATH,
    clean: true,
    export_team_id: get_required_env("EXT_EXPORT_TEAM_ID"),
    output_directory: BUILD_PRODUCTS_PATH,
    derived_data_path: DERIVED_DATA_PATH,
    export_options: { method: "app-store" }
  )

  testflight(
    skip_waiting_for_build_processing: true,
    team_id: "299112",
    api_key_path: APP_STORE_CONNECT_KEY_PATH
  )

  sentry_upload_dsym(
    auth_token: get_required_env("SENTRY_AUTH_TOKEN"),
    org_slug: 'a8c',
    project_slug: 'jetpack-ios',
    dsym_path: lane_context[SharedValues::DSYM_OUTPUT_PATH]
  )

end

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

desc "Build Jetpack for Testing"
lane :build_jetpack_for_testing do | options |
  run_tests(
    workspace: WORKSPACE_PATH,
    scheme: "Jetpack",
    derived_data_path: DERIVED_DATA_PATH,
    build_for_testing: true,
    deployment_target_version: options[:ios_version],
  )
end



#################################################
# Helper functions
#################################################


# This function is Buildkite-specific
def generate_installable_build_number

  if ENV['BUILDKITE']
    commit = ENV['BUILDKITE_COMMIT'][0,7]
    branch = ENV['BUILDKITE_BRANCH']
    pr_num = ENV['BUILDKITE_PULL_REQUEST']

    return pr_num == 'false' ? "#{branch}-#{commit}" : "pr#{pr_num}-#{commit}"
  else
    repo = Git.open(PROJECT_ROOT_FOLDER)
    commit = repo.current_branch
    branch = repo.revparse('HEAD')[0, 7]

    return "#{branch}-#{commit}"
  end
end
