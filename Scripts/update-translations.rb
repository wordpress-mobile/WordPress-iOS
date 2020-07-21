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

ALL_LANGS={
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
}

REVIEW_LANGS={
  'ar' => 'ar',         # Arabic
  'de' => 'de',         # German
  'es' => 'es',         # Spanish
  'fr' => 'fr',         # French
  'he' => 'he',         # Hebrew
  'id' => 'id',         # Indonesian
  'it' => 'it',         # Italian
  'ja' => 'ja',         # Japanese
  'ko' => 'ko',         # Korean
  'nl' => 'nl',         # Dutch
  'pt-br' => 'pt-BR',   # Portuguese (Brazil)
  'ru' => 'ru',         # Russian
  'sv' => 'sv',         # Swedish
  'tr' => 'tr',         # Turkish
  'zh-cn' => 'zh-Hans', # Chinese (China)
  'zh-tw' => 'zh-Hant', # Chinese (Taiwan)
}

langs = {}
strings_filter = ""
strings_file_ext = ""
download_url = "https://translate.wordpress.org/projects/apps/ios/dev"
if ARGV.count > 0
  if (ARGV[0] == "review") then
    langs = REVIEW_LANGS

    strings_filter = "filters[status]=#{ARGV[1]}\&"
    strings_file_ext = "_#{ARGV[1]}"
    download_url = "https://translate.wordpress.com/projects/wporg/apps/ios/"
  else
    for key in ARGV
      unless local = ALL_LANGS[key]
        puts "Unknown language #{key}"
        exit 1
      end
      langs[key] = local
    end
  end 
else
  langs = ALL_LANGS
end

langs.each do |code,local|
  lang_dir = File.join('WordPress', 'Resources', "#{local}.lproj")
  puts "Updating #{code}"
  system "mkdir -p #{lang_dir}"

  # Download for production
  system "if [ -e #{lang_dir}/Localizable#{strings_file_ext}.strings ]; then cp #{lang_dir}/Localizable#{strings_file_ext}.strings #{lang_dir}/Localizable#{strings_file_ext}.strings.bak; fi"

  url = "#{download_url}/#{code}/default/export-translations?#{strings_filter}format=strings"
  destination = "#{lang_dir}/Localizable#{strings_file_ext}.strings"

  system "curl -fLso #{destination} \"#{url}\"" or begin
    puts "Error downloading #{code}"
  end

  if File.size(destination).to_f == 0
    abort("\e[31mFatal Error: #{destination} appears to be empty. Exiting.\e[0m")
  end

  system "./Scripts/fix-translation #{lang_dir}/Localizable#{strings_file_ext}.strings"
  system "plutil -lint #{lang_dir}/Localizable#{strings_file_ext}.strings" and system "rm #{lang_dir}/Localizable#{strings_file_ext}.strings.bak"
  system "grep -a '\\x00\\x20\\x00\\x22\\x00\\x22\\x00\\x3b$' #{lang_dir}/Localizable#{strings_file_ext}.strings"
end
system "Scripts/extract-framework-translations.swift" if strings_filter.empty? 
