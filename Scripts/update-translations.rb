#!/usr/bin/env ruby
# encoding: utf-8

# Supported languages:
# ar,ca,cs,cy,da,de,el,en,en-CA,en-GB,es,fi,fr,he,hr,hu,id,it,ja,ko,ms,nb,nl,pl,pt,pt-PT,ro,ru,sk,sv,th,tr,uk,vi,zh-Hans,zh-Hant
# * Arabic
# * Catalan
# * Czech
# * Danish
# * German
# * Greek
# * English
# * English (Canada eh)
# * English (UK)
# * Spanish
# * Finnish
# * French
# * Hebrew
# * Croatian
# * Hungarian
# * Indonesian
# * Italian
# * Japanese
# * Korean
# * Malay
# * Norwegian (Bokmål)
# * Dutch
# * Polish
# * Portuguese
# * Portuguese (Portugal)
# * Romanian
# * Russian
# * Slovak
# * Swedish
# * Thai
# * Turkish
# * Ukranian
# * Vietnamese
# * Chinese (China) [zh-Hans]
# * Chinese (Taiwan) [zh-Hant]
# * Welsh

if Dir.pwd =~ /Scripts/
  puts "Must run script from root folder"
  exit
end

LANGS={
  'ar' => 'ar',         # Arabic
  'da' => 'da',         # Danish
  'de' => 'de',         # German
  'es' => 'es',         # Spanish
  'fr' => 'fr',         # French
  'he' => 'he',         # Hebrew
  'hr' => 'hr',         # Croatian
  'hu' => 'hu',         # Hungarian
  'id' => 'id',         # Indonesian
  'it' => 'it',         # Italian
  'ja' => 'ja',         # Japanese
  'ko' => 'ko',         # Korean
  'nb' => 'nb',         # Norwegian (Bokmål)
  'nl' => 'nl',         # Dutch
  'pl' => 'pl',         # Polish
  'pt' => 'pt',         # Portuguese
  'ru' => 'ru',         # Russian
  'sv' => 'sv',         # Swedish
  'th' => 'th',         # Thai
  'tr' => 'tr',         # Turkish
  'zh-cn' => 'zh-Hans', # Chinese (China)
  'zh-tw' => 'zh-Hant', # Chinese (Taiwan)
  'pt-br' => 'pt-BR',   # Portuguese (Brazil)
  'en-gb' => 'en-GB',   # English (UK)
  'en-ca' => 'en-CA',   # English (Canada)
  'cy' => 'cy',         # Welsh
}

LANGS.each do |code,local|
  lang_dir = File.join('WordPress', 'Resources', "#{local}.lproj")
  puts "Updating #{code}"
  system "cp #{lang_dir}/Localizable.strings #{lang_dir}/Localizable.strings.bak"
  system "curl -fso #{lang_dir}/Localizable.strings https://translate.wordpress.org/projects/apps/ios/dev/#{code}/default/export-translations?format=strings" or begin
    puts "Error downloading #{code}"
  end
  system "php Scripts/fix-translation.php #{lang_dir}/Localizable.strings"
  system "plutil -lint #{lang_dir}/Localizable.strings" and system "rm #{lang_dir}/Localizable.strings.bak"
  system "grep -a '\\x00\\x22\\x00\\x22' #{lang_dir}/Localizable.strings"
end
