# frozen_string_literal: true

# Lanes related to Code Signing and Provisioning Profiles
#
platform :ios do
  # Registers a new device in the Developer Portal and update all the Provisioning Profiles
  #
  # @option [String] device_name name to give to the device. Will be prompted interactively if not provided.
  # @option [String] device_id UDID of the device to add. Will be prompted interactively if not provided.
  #
  desc 'Registers a Device in the developer console'
  lane :register_new_device do |options|
    device_name = UI.input('Device Name: ') if options[:device_name].nil?
    device_id = UI.input('Device ID: ') if options[:device_id].nil?
    all_bundle_ids = ALL_BUNDLE_IDENTIFIERS + [JETPACK_APP_IDENTIFIER]

    UI.message "Registering #{device_name} with ID #{device_id} and registering it with any provisioning profiles associated with these bundle identifiers:"
    all_bundle_ids.each do |identifier|
      puts "\t#{identifier}"
    end

    team_id = get_required_env('EXT_EXPORT_TEAM_ID')

    # Register the user's device
    register_device(
      name: device_name,
      udid: device_id,
      team_id: team_id,
      api_key_path: APP_STORE_CONNECT_KEY_PATH
    )

    # We're about to use `add_development_certificates_to_provisioning_profiles` and `add_all_devices_to_provisioning_profiles`.
    # These actions use Developer Portal APIs that don't yet support authentication via API key (-.-').
    # Let's preemptively ask for and set the email here to avoid being asked twice for it if not set.

    require 'credentials_manager'

    # If Fastlane cannot instantiate a user, it will ask the caller for the email.
    # Once we have it, we can set it as `FASTLANE_USER` in the environment (which has lifecycle limited to this call) so that the next commands will already have access to it.
    # Note that if the user is already available to `AccountManager`, setting it in the environment is redundant, but Fastlane doesn't provide a way to check it so we have to do it anyway.
    ENV['FASTLANE_USER'] = CredentialsManager::AccountManager.new.user

    # Add all development certificates to the provisioning profiles (just in case – this is an easy step to miss)
    add_development_certificates_to_provisioning_profiles(
      team_id: team_id,
      app_identifier: all_bundle_ids
    )

    # Add all devices to the provisioning profiles
    add_all_devices_to_provisioning_profiles(
      team_id: team_id,
      app_identifier: all_bundle_ids
    )
  end

  # Downloads all the required certificates and profiles (using `match`) for all variants
  #
  lane :update_certs_and_profiles do
    update_wordpress_certs_and_profiles
    update_jetpack_certs_and_profiles
  end

  # Downloads all the required certificates and profiles (using `match`) for all WordPress variants
  #
  lane :update_wordpress_certs_and_profiles do
    alpha_code_signing
    internal_code_signing
    appstore_code_signing
  end

  # Downloads all the required certificates and profiles (using `match`) for all Jetpack variants
  #
  lane :update_jetpack_certs_and_profiles do
    jetpack_alpha_code_signing
    jetpack_internal_code_signing
    jetpack_appstore_code_signing
  end

  ########################################################################
  # Private lanes
  ########################################################################

  # Downloads all the required certificates and profiles (using `match``) for the WordPress Alpha builds (`org.wordpress.alpha`) in the Enterprise account
  #
  private_lane :alpha_code_signing do
    match(
      type: 'enterprise',
      team_id: get_required_env('INT_EXPORT_TEAM_ID'),
      readonly: true,
      app_identifier: ALL_BUNDLE_IDENTIFIERS.map { |id| id.sub(APP_STORE_VERSION_BUNDLE_IDENTIFIER, 'org.wordpress.alpha') }
    )
  end

  # Downloads all the required certificates and profiles (using `match``) for the WordPress Internal builds (`org.wordpress.internal`) in the Enterprise account
  #
  private_lane :internal_code_signing do
    match(
      type: 'enterprise',
      team_id: get_required_env('INT_EXPORT_TEAM_ID'),
      readonly: true,
      app_identifier: ALL_BUNDLE_IDENTIFIERS.map { |id| id.sub(APP_STORE_VERSION_BUNDLE_IDENTIFIER, 'org.wordpress.internal') }
    )
  end

  # Downloads all the required certificates and profiles (using `match``) for the WordPress App Store builds
  #
  private_lane :appstore_code_signing do
    match(
      type: 'appstore',
      team_id: get_required_env('EXT_EXPORT_TEAM_ID'),
      readonly: true,
      app_identifier: ALL_BUNDLE_IDENTIFIERS
    )
  end

  # Downloads all the required certificates and profiles (using `match``) for the Jetpack Alpha builds (`com.jetpack.alpha`) in the Enterprise account
  #
  private_lane :jetpack_alpha_code_signing do
    match(
      type: 'enterprise',
      team_id: get_required_env('INT_EXPORT_TEAM_ID'),
      readonly: true,
      app_identifier: 'com.jetpack.alpha'
    )
  end

  # Downloads all the required certificates and profiles (using `match``) for the Jetpack Internal builds (`com.jetpack.internal`) in the Enterprise account
  #
  private_lane :jetpack_internal_code_signing do
    match(
      type: 'enterprise',
      team_id: get_required_env('INT_EXPORT_TEAM_ID'),
      readonly: true,
      app_identifier: 'com.jetpack.internal'
    )
  end

  # Downloads all the required certificates and profiles (using `match``) for the Jetpack App Store builds
  #
  private_lane :jetpack_appstore_code_signing do
    match(
      type: 'appstore',
      team_id: get_required_env('EXT_EXPORT_TEAM_ID'),
      readonly: true,
      app_identifier: JETPACK_APP_IDENTIFIER
    )
  end
end
