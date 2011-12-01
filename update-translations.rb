#!/usr/bin/env ruby -wKU

# Supported languages:
# ar,ca,cs,da,de,el,en,en-GB,es,fi,fr,he,hr,hu,id,it,ja,ko,ms,nb,nl,pl,pt,pt-PT,ro,ru,sk,sv,th,tr,uk,vi,zh-Hans,zh-Hant

LANGS={
  'de' => 'de',
  'es' => 'es',
  'fr' => 'fr',
  'he' => 'he',
  'hr' => 'hr',
  'id' => 'id',
  'it' => 'it',
  'ja' => 'ja',
  'nb' => 'nb',
  'nl' => 'nl',
  'pt' => 'pt',
  'sv' => 'sv',
  'tr' => 'tr',
  'zh-cn' => 'zh-Hans'
}

LANGS.each do |code,local|
  puts "Updating #{code}"
  system "cp #{local}.lproj/Localizable.strings #{local}.lproj/Localizable.strings.bak"
  system "curl -so #{local}.lproj/Localizable.strings http://translate.wordpress.org/projects/ios/dev/#{code}/default/export-translations?format=strings" or begin
    puts "Error downloading #{code}"
  end
  system "plutil -lint #{local}.lproj/Localizable.strings" and system "rm #{local}.lproj/Localizable.strings.bak"
  system "grep -aP '\\x00\\x22\\x00\\x22' #{local}.lproj/Localizable.strings"
end