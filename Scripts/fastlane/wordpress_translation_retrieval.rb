require 'rubygems'

class WordPressTranslationRetrieval

  LANGS = {
    'en-US' => 'en-gb', # Technically this is a hack, but I don't think we can get the original english translations from Glotpress
    'en-CA' => 'en-gb',
    'en-AU' => 'en-au',
    'es-ES' => 'es',
    'en-GB' => 'en-gb',
    'fr-FR' => 'fr',
    'it-IT' => 'it',
    'ja-JP' => 'ja',
    'sv-SE' => 'sv',
    'pt-BR' => 'pt-br',
    'nl-NL' => 'nl',
    'de-DE' => 'de',
    'id-ID' => 'id',
    'ko-KR' => 'ko',
    'ru-RU' => 'ru',
    'cmn-Hant' => 'zh-tw',
    'th-TH' => 'th',
    'cmn-Hans' => 'zh-cn',
    'tr-TR' => 'tr',
  }

  class << self

    def get_version_text_from_file_contents(file_contents, strings_file_key)
      whats_new_text = nil

      file_contents.each_with_index do |line, index|
        if line =~ Regexp.new(strings_file_key)
          whats_new_text = file_contents[index+2]
          if whats_new_text =~ Regexp.new("msgstr\s\"\"")
            whats_new_text = file_contents[index+1]
          end
        end
      end

      separator = "•"
      matcher = Regexp.new("\"(.*)\"")
      matches = whats_new_text.gsub("msgstr ", "").match(matcher)
      version_text = matches[1].split(separator).select { |text| text.length > 0 }.map { |text| text.strip }.map { |text| "#{separator} #{text}"}.join("\n")

      version_text
    end

    def retrieve_file_contents_from_glotpress(glotpress_language_code)
      url = "https://translate.wordpress.org/projects/apps/ios/release-notes/#{glotpress_language_code}/default/export-translations?format=po"
      system "curl -so temp.po #{url}"
      file_contents = File.readlines("temp.po")
      system "rm temp.po"

      file_contents
    end

    def get_version_text(deliver_language_code, strings_file_key)
      glotpress_language_code = LANGS[deliver_language_code]
      file_contents = retrieve_file_contents_from_glotpress(glotpress_language_code)
      version_text = get_version_text_from_file_contents(file_contents, strings_file_key)

      if version_text.length == 0
        file_contents = retrieve_file_contents_from_glotpress("en-gb")
        version_text = get_version_text_from_file_contents(file_contents, strings_file_key)
      end

      version_text
    end
  end

end

# Uncomment below and run the script from the command line to test
# WordPressTranslationRetrieval::LANGS.each do |deliver_language_code, glotpress_language_code|
#   puts "Version text for #{deliver_language_code}"
#   puts WordPressTranslationRetrieval.get_version_text(deliver_language_code, "v4.8-whats-new")
#   puts "\n"
# end

