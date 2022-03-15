# frozen_string_literal: true

#################################################
# Constants
#################################################

# URL of the GlotPress project which contains App strings
GLOTPRESS_APP_STRINGS_URL = 'https://translate.wordpress.org/projects/apps/ios/dev/'

# URL of the GlotPress projects containing AppStore metadata (title, keywords, release notes, …)
GLOTPRESS_WORDPRESS_METADATA_PROJECT_URL = 'https://translate.wordpress.org/projects/apps/ios/release-notes/'
GLOTPRESS_JETPACK_METADATA_PROJECT_URL = 'https://translate.wordpress.com/projects/jetpack/apps/ios/release-notes/',

# List of locales used for the app strings
# TODO: Replace with `LocaleHelper` once provided by release toolkit (https://github.com/wordpress-mobile/release-toolkit/pull/296)
#
GLOTPRESS_TO_LPROJ_APP_LOCALE_CODES = {
  'ar' => 'ar',         # Arabic
  'bg' => 'bg',         # Bulgarian
  'cs' => 'cs',         # Czech
  'cy' => 'cy',         # Welsh
  'da' => 'da',         # Danish
  'de' => 'de',         # German
  'en-au' => 'en-AU',   # English (Australia)
  'en-ca' => 'en-CA',   # English (Canada)
  'en-gb' => 'en-GB',   # English (UK)
  'es' => 'es',         # Spanish
  'fr' => 'fr',         # French
  'he' => 'he',         # Hebrew
  'hr' => 'hr',         # Croatian
  'hu' => 'hu',         # Hungarian
  'id' => 'id',         # Indonesian
  'is' => 'is',         # Icelandic
  'it' => 'it',         # Italian
  'ja' => 'ja',         # Japanese
  'ko' => 'ko',         # Korean
  'nb' => 'nb',         # Norwegian (Bokmål)
  'nl' => 'nl',         # Dutch
  'pl' => 'pl',         # Polish
  'pt' => 'pt',         # Portuguese
  'pt-br' => 'pt-BR',   # Portuguese (Brazil)
  'ro' => 'ro',         # Romainian
  'ru' => 'ru',         # Russian
  'sk' => 'sk',         # Slovak
  'sq' => 'sq',         # Albanian
  'sv' => 'sv',         # Swedish
  'th' => 'th',         # Thai
  'tr' => 'tr',         # Turkish
  'zh-cn' => 'zh-Hans', # Chinese (China)
  'zh-tw' => 'zh-Hant', # Chinese (Taiwan)
}.freeze


# List of `.strings` files manually maintained by developers (as opposed to being automatically extracted from code and generated)
# which we will merge into the main `Localizable.strings` file imported by GlotPress, then extract back once we download the translations.
# Each `.strings` file to be merged/extracted is associated with a prefix to add the the keys being used to avoid conflicts and differentiate.
# See calls to `ios_merge_strings_files` and `ios_extract_keys_from_strings_files` for usage.
#
MANUALLY_MAINTAINED_STRINGS_FILES = {
  File.join('WordPress', 'Resources', 'en.lproj', 'InfoPlist.strings') => 'infoplist.', # For now WordPress and Jetpack share the same InfoPlist.strings
  File.join('WordPress', 'WordPressDraftActionExtension', 'en.lproj', 'InfoPlist.strings') => 'ios-sharesheet.', # CFBundleDisplayName for the "Save as Draft" share action
  File.join('WordPress', 'WordPressIntents', 'en.lproj', 'Sites.strings') => 'ios-widget.' # Strings from the `.intentdefinition`, used for configuring the iOS Widget
}.freeze
