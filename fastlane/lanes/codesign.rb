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
    all_bundle_ids = ALL_WORDPRESS_BUNDLE_IDENTIFIERS + ALL_JETPACK_BUNDLE_IDENTIFIERS

    UI.message "Registering #{device_name} with ID #{device_id} and registering it with any provisioning profiles associated with these bundle identifiers:"
    all_bundle_ids.each do |identifier|
      puts "\t#{identifier}"
    end

    team_id = get_required_env('EXT_EXPORT_TEAM_ID')

    # Register the user's device
    register_device(
      name: device_name,
      udid: device_id,
      team_id:,
      api_key_path: APP_STORE_CONNECT_KEY_PATH
    )

    # We're about to use `add_development_certificates_to_provisioning_profiles` and `add_all_devices_to_provisioning_profiles`.
    # These actions use Developer Portal APIs that don't yet support authentication via API key (-.-').
    # Let's preemptively ask for and set the email here to avoid being asked twice for it if not set.
    prompt_user_for_app_store_connect_credentials

    # Add all development certificates to the provisioning profiles (just in case – this is an easy step to miss)
    add_development_certificates_to_provisioning_profiles(
      team_id:,
      app_identifier: all_bundle_ids
    )

    # Add all devices to the provisioning profiles
    add_all_devices_to_provisioning_profiles(
      team_id:,
      app_identifier: all_bundle_ids
    )
  end

  # Downloads all the required certificates and profiles (using `match`) for all variants.
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  lane :update_certs_and_profiles do |options|
    update_wordpress_certs_and_profiles(options)
    update_jetpack_certs_and_profiles(options)
  end

  # Downloads all the required certificates and profiles (using `match`) for all WordPress variants.
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  lane :update_wordpress_certs_and_profiles do |options|
    alpha_code_signing(options)
    internal_code_signing(options)
    appstore_code_signing(options)
  end

  # Downloads all the required certificates and profiles (using `match`) for all Jetpack variants.
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  lane :update_jetpack_certs_and_profiles do |options|
    jetpack_alpha_code_signing(options)
    jetpack_internal_code_signing(options)
    jetpack_appstore_code_signing(options)
  end

  ########################################################################
  # Private lanes
  ########################################################################

  # Downloads all the required certificates and profiles (using `match``) for the WordPress Alpha builds (`org.wordpress.alpha`) in the Enterprise account
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  private_lane :alpha_code_signing do |options|
    update_code_signing_enterprise(
      app_identifiers: ALL_WORDPRESS_BUNDLE_IDENTIFIERS.map { |id| id.sub(WORDPRESS_BUNDLE_IDENTIFIER, 'org.wordpress.alpha') },
      readonly: options.fetch(:readonly, true)
    )
  end

  # Downloads all the required certificates and profiles (using `match``) for the WordPress Internal builds (`org.wordpress.internal`) in the Enterprise account.
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  private_lane :internal_code_signing do |options|
    update_code_signing_enterprise(
      app_identifiers: ALL_WORDPRESS_BUNDLE_IDENTIFIERS.map { |id| id.sub(WORDPRESS_BUNDLE_IDENTIFIER, 'org.wordpress.internal') },
      readonly: options.fetch(:readonly, true)
    )
  end

  # Downloads all the required certificates and profiles (using `match``) for the WordPress App Store builds
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  private_lane :appstore_code_signing do |options|
    update_code_signing_app_store(
      readonly: options.fetch(:readonly, true),
      app_identifiers: ALL_WORDPRESS_BUNDLE_IDENTIFIERS
    )
  end

  # Downloads all the required certificates and profiles (using `match``) for the Jetpack Alpha builds (`com.jetpack.alpha`) in the Enterprise account.
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  private_lane :jetpack_alpha_code_signing do |options|
    update_code_signing_enterprise(
      app_identifiers: ALL_JETPACK_BUNDLE_IDENTIFIERS.map { |id| id.sub(JETPACK_BUNDLE_IDENTIFIER, 'com.jetpack.alpha') },
      readonly: options.fetch(:readonly, true)
    )
  end

  # Downloads all the required certificates and profiles (using `match``) for the Jetpack Internal builds (`com.jetpack.internal`) in the Enterprise account.
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  private_lane :jetpack_internal_code_signing do |options|
    update_code_signing_enterprise(
      app_identifiers: ALL_JETPACK_BUNDLE_IDENTIFIERS.map { |id| id.sub(JETPACK_BUNDLE_IDENTIFIER, 'com.jetpack.internal') },
      readonly: options.fetch(:readonly, true)
    )
  end

  # Downloads all the required certificates and profiles (using `match``) for the Jetpack App Store builds.
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  private_lane :jetpack_appstore_code_signing do |options|
    update_code_signing_app_store(
      readonly: options.fetch(:readonly, true),
      app_identifiers: ALL_JETPACK_BUNDLE_IDENTIFIERS
    )
  end
end

def update_code_signing_enterprise(readonly:, app_identifiers:)
  if readonly
    # In readonly mode, we can use the API key
    api_key_path = APP_STORE_CONNECT_KEY_PATH
  else
    # The Enterprise account APIs do not support authentication via API key.
    # If we want to modify data (readonly = false) we need to authenticate manually.
    prompt_user_for_app_store_connect_credentials
    # We also need to pass no API key path, otherwise Fastlane will give
    # precedence to that authentication mode.
    api_key_path = nil
  end

  update_code_signing(
    type: 'enterprise',
    # Enterprise builds belong to the "internal" team
    team_id: get_required_env('INT_EXPORT_TEAM_ID'),
    readonly:,
    app_identifiers:,
    api_key_path:
  )
end

def update_code_signing_app_store(readonly:, app_identifiers:)
  update_code_signing(
    type: 'appstore',
    # App Store builds belong to the "external" team
    team_id: get_required_env('EXT_EXPORT_TEAM_ID'),
    readonly:,
    app_identifiers:,
    api_key_path: APP_STORE_CONNECT_KEY_PATH
  )
end

def update_code_signing(type:, team_id:, readonly:, app_identifiers:, api_key_path:)
  # NOTE: It might be neccessary to add `force: true` alongside `readonly: true` in order to regenerate some provisioning profiles.
  # If this turns out to be a hard requirement, we should consider updating the method with logic to toggle the two setting based on whether we're fetching or renewing.
  match(
    storage_mode: 'google_cloud',
    google_cloud_bucket_name: 'a8c-fastlane-match',
    google_cloud_keys_file: File.join(SECRETS_DIR, 'google_cloud_keys.json'),
    type:,
    team_id:,
    readonly:,
    app_identifier: app_identifiers,
    api_key_path:
  )
end

def prompt_user_for_app_store_connect_credentials
  require 'credentials_manager'

  # If Fastlane cannot instantiate a user, it will ask the caller for the email.
  # Once we have it, we can set it as `FASTLANE_USER` in the environment (which has lifecycle limited to this call) so that the next commands will already have access to it.
  # Note that if the user is already available to `AccountManager`, setting it in the environment is redundant, but Fastlane doesn't provide a way to check it so we have to do it anyway.
  ENV['FASTLANE_USER'] = CredentialsManager::AccountManager.new.user
end
