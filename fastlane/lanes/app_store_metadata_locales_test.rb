# frozen_string_literal: true

# Pure-Ruby unit suite for the App Store metadata locale folders.
# Run directly: `ruby fastlane/lanes/app_store_metadata_locales_test.rb`.
require 'minitest/autorun'

# `deliver` derives the set of locales it uploads from the *names* of the directories under the metadata
# path, ignoring their contents, and only applies the `default/` fallback to locales already in that set.
# A locale App Store Connect declares but we have no folder for is therefore silently never uploaded, and
# its "What's New" stays empty until submission fails (AINFRA-2602). These lists mirror the localizations
# declared on App Store Connect; adding one there means adding a folder here, even an empty one.
class AppStoreMetadataLocalesTest < Minitest::Test
  JETPACK_APP_STORE_CONNECT_LOCALES = %w[
    ar-SA de-DE en-GB en-US es-ES fr-FR he id it ja ko nl-NL pt-BR ru sv tr zh-Hans zh-Hant
  ].freeze

  def metadata_locales(dir)
    path = File.join(__dir__, '..', dir)
    Dir.children(path)
       .select { |entry| File.directory?(File.join(path, entry)) }
       .reject { |entry| entry == 'default' }
       .sort
  end

  def test_jetpack_has_a_folder_for_every_locale_app_store_connect_declares
    assert_equal JETPACK_APP_STORE_CONNECT_LOCALES.sort, metadata_locales('jetpack_metadata')
  end

  def test_jetpack_enrols_en_gb
    assert_includes metadata_locales('jetpack_metadata'), 'en-GB'
  end

  def test_wordpress_enrols_en_gb
    assert_includes metadata_locales('metadata'), 'en-GB'
  end

  # An en-GB folder with no `release_notes.txt` is intentional: `deliver` fills it from `default/`, as it
  # already does for en-US. The folder only has to exist.
  def test_locale_folders_need_no_release_notes_of_their_own
    refute_path_exists File.join(__dir__, '..', 'metadata', 'en-US', 'release_notes.txt')
  end
end
