#!/usr/bin/env ruby -wKU

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