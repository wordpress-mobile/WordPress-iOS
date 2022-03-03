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

