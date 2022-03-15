# frozen_string_literal: true

#####################################################################################
# register_new_device
# -----------------------------------------------------------------------------------
# This lane helps a developer register a new device in the App Store Portal
# -----------------------------------------------------------------------------------
# Usage:
# bundle exec fastlane register_new_device
#
# Example:
# bundle exec fastlane register_new_device
#####################################################################################
desc 'Registers a Device in the developer console'
lane :register_new_device do |options|
  device_name = UI.input('Device Name: ') if options[:device_name].nil?
  device_id = UI.input('Device ID: ') if options[:device_id].nil?
  UI.message "Registering #{device_name} with ID #{device_id} and registering it with any provisioning profiles associated with these bundle identifiers:"
  ALL_BUNDLE_IDENTIFIERS.each do |identifier|
    puts "\t#{identifier}"
  end

  # Register the user's device
  register_device(
    name: device_name,
    udid: device_id,
    team_id: get_required_env('EXT_EXPORT_TEAM_ID')
  )

  # Add all development certificates to the provisioning profiles (just in case – this is an easy step to miss)
  add_development_certificates_to_provisioning_profiles(
    team_id: get_required_env('EXT_EXPORT_TEAM_ID'),
    app_identifier: ALL_BUNDLE_IDENTIFIERS
  )

  # Add all devices to the provisioning profiles
  add_all_devices_to_provisioning_profiles(
    team_id: get_required_env('EXT_EXPORT_TEAM_ID'),
    app_identifier: ALL_BUNDLE_IDENTIFIERS
  )
end

#####################################################################################
# update_certs_and_profiles
# -----------------------------------------------------------------------------------
# This lane downloads all the required certs and profiles and,
# if not run on CI it creates the missing ones.
# -----------------------------------------------------------------------------------
# Usage:
# bundle exec fastlane update_certs_and_profiles
#
# Example:
# bundle exec fastlane update_certs_and_profiles
#####################################################################################
lane :update_certs_and_profiles do |_options|
  alpha_code_signing
  internal_code_signing
  appstore_code_signing
end

########################################################################
# Fastlane match code signing
########################################################################
private_lane :alpha_code_signing do |_options|
  match(
    type: 'enterprise',
    team_id: get_required_env('INT_EXPORT_TEAM_ID'),
    readonly: true,
    app_identifier: ALL_BUNDLE_IDENTIFIERS.map { |id| id.sub(APP_STORE_VERSION_BUNDLE_IDENTIFIER, 'org.wordpress.alpha') }
  )
end

private_lane :internal_code_signing do |_options|
  match(
    type: 'enterprise',
    team_id: get_required_env('INT_EXPORT_TEAM_ID'),
    readonly: true,
    app_identifier: ALL_BUNDLE_IDENTIFIERS.map { |id| id.sub(APP_STORE_VERSION_BUNDLE_IDENTIFIER, 'org.wordpress.internal') }
  )
end

private_lane :appstore_code_signing do |_options|
  match(
    type: 'appstore',
    team_id: get_required_env('EXT_EXPORT_TEAM_ID'),
    readonly: true,
    app_identifier: ALL_BUNDLE_IDENTIFIERS
  )
end

########################################################################
# Jetpack Fastlane match code signing
########################################################################
private_lane :jetpack_alpha_code_signing do |options|
  match(
    type: "enterprise",
    team_id: get_required_env("INT_EXPORT_TEAM_ID"),
    readonly: true,
    app_identifier: "com.jetpack.alpha"
  )
end

private_lane :jetpack_internal_code_signing do |options|
  match(
    type: "enterprise",
    team_id: get_required_env("INT_EXPORT_TEAM_ID"),
    readonly: true,
    app_identifier: "com.jetpack.internal"
  )
end

private_lane :jetpack_appstore_code_signing do |options|
  match(
    type: "appstore",
    team_id: get_required_env("EXT_EXPORT_TEAM_ID"),
    readonly: true,
    app_identifier: JETPACK_APP_IDENTIFIER
  )
end
