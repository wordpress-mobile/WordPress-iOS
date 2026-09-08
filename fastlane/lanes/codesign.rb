# frozen_string_literal: true

CODE_SIGNING_STORAGE_OPTIONS = {
  storage_mode: 's3',
  s3_bucket: 'a8c-fastlane-match',
  s3_region: 'us-east-2'
}.freeze

# Lanes related to Code Signing and Provisioning Profiles
#
platform :ios do
  # Downloads all the required certificates and profiles (using `match`) for all variants.
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  lane :update_certs_and_profiles do |options|
    update_certs_and_profiles_wordpress(options)
    update_certs_and_profiles_jetpack(options)
  end

  # Downloads all the required certificates and profiles (using `match`) for all WordPress variants.
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  lane :update_certs_and_profiles_wordpress do |readonly: true|
    update_certs_and_profiles_wordpress_enterprise(readonly: readonly)
    update_certs_and_profiles_wordpress_app_store(readonly: readonly)
  end

  # Downloads all the required certificates and profiles (using `match`) for all Jetpack variants.
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  lane :update_certs_and_profiles_jetpack do |readonly: true|
    update_certs_and_profiles_jetpack_enterprise(readonly: readonly)
    update_certs_and_profiles_jetpack_app_store(readonly: readonly)
  end

  # Downloads all the required certificates and profiles (using `match``) for the WordPress Alpha builds (`org.wordpress.alpha`) in the Enterprise account
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  lane :update_certs_and_profiles_wordpress_enterprise do |readonly: true|
    update_code_signing_enterprise(
      app_identifiers: ALL_WORDPRESS_BUNDLE_IDENTIFIERS.map { |id| id.sub(WORDPRESS_BUNDLE_IDENTIFIER, 'org.wordpress.alpha') },
      readonly: readonly
    )
  end

  # Downloads all the required certificates and profiles (using `match``) for the WordPress App Store builds
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  lane :update_certs_and_profiles_wordpress_app_store do |readonly: true|
    update_code_signing_app_store(
      app_identifiers: ALL_WORDPRESS_BUNDLE_IDENTIFIERS,
      readonly: readonly
    )
  end

  # Downloads all the required certificates and profiles (using `match``) for the Jetpack Alpha builds (`com.jetpack.alpha`) in the Enterprise account.
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  lane :update_certs_and_profiles_jetpack_enterprise do |readonly: true|
    update_code_signing_enterprise(
      app_identifiers: ALL_JETPACK_BUNDLE_IDENTIFIERS.map { |id| id.sub(JETPACK_BUNDLE_IDENTIFIER, 'com.jetpack.alpha') },
      readonly: readonly
    )
  end

  # Downloads all the required certificates and profiles (using `match``) for the Jetpack App Store builds.
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  lane :update_certs_and_profiles_jetpack_app_store do |readonly: true|
    update_code_signing_app_store(
      app_identifiers: ALL_JETPACK_BUNDLE_IDENTIFIERS,
      readonly: readonly
    )
  end

  # Downloads all the required certificates and profiles (using `match``) for the Reader App Store builds.
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  lane :update_certs_and_profiles_app_store_reader do |readonly: true|
    update_code_signing_app_store(
      app_identifiers: ALL_READER_BUNDLE_IDENTIFIERS,
      readonly: readonly
    )
  end

  # Downloads all the required certificates and profiles (using `match`) for both Jetpack and WordPress App Store variants.
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  lane :update_certs_and_profiles_app_store do |readonly: true|
    update_certs_and_profiles_app_store_reader(readonly: readonly)
    update_certs_and_profiles_jetpack_app_store(readonly: readonly)
    update_certs_and_profiles_wordpress_app_store(readonly: readonly)
  end

  # Downloads all the required certificates and profiles (using `match`) for both Jetpack and WordPress Enterprise variants.
  # Optionally, it can create any new necessary certificate or profile.
  #
  # @option [Boolean] readonly (default: true) Whether to only fetch existing certificates and profiles, without generating new ones.
  #
  lane :update_certs_and_profiles_enterprise do |readonly: true|
    update_certs_and_profiles_jetpack_enterprise(readonly: readonly)
    update_certs_and_profiles_wordpress_enterprise(readonly: readonly)
  end
end

def update_code_signing_enterprise(readonly:, app_identifiers:)
  update_code_signing(
    type: 'enterprise',
    # Enterprise builds belong to the "internal" team
    team_id: INTERNAL_TEAM_ID,
    readonly: readonly,
    app_identifiers: app_identifiers,
    # `match` only authenticates when it has to generate something, so readonly runs need no key.
    api_key: readonly ? nil : enterprise_app_store_connect_api_key
  )
end

def enterprise_app_store_connect_api_key
  app_store_connect_api_key(
    key_id: get_required_env('APP_STORE_CONNECT_API_KEY_KEY_ID_ENTERPRISE'),
    issuer_id: get_required_env('APP_STORE_CONNECT_API_KEY_ISSUER_ID_ENTERPRISE'),
    key_content: get_required_env('APP_STORE_CONNECT_API_KEY_KEY_ENTERPRISE'),
    in_house: true
  )
end

def update_code_signing_app_store(readonly:, app_identifiers:)
  update_code_signing(
    type: 'appstore',
    # App Store builds belong to the "external" team
    team_id: EXTERNAL_TEAM_ID,
    readonly: readonly,
    app_identifiers: app_identifiers,
    api_key: app_store_connect_api_key
  )
end

def update_code_signing(type:, team_id:, readonly:, app_identifiers:, api_key:)
  # NOTE: It might be necessary to add `force: true` alongside `readonly: true` in order to regenerate some provisioning profiles.
  # If this turns out to be a hard requirement, we should consider updating the method with logic to toggle the two setting based on whether we're fetching or renewing.
  match(
    type: type,
    team_id: team_id,
    readonly: readonly,
    app_identifier: app_identifiers,
    api_key: api_key,
    **CODE_SIGNING_STORAGE_OPTIONS
  )
end
