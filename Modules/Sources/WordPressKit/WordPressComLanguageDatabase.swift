import Foundation

/// This helper class allows us to map WordPress.com LanguageID's into human readable language strings.
///
class WordPressComLanguageDatabase: NSObject {
    // MARK: - Properties

    /// Languages considered 'popular'
    ///
    let popular: [Language]

    /// Every supported language
    ///
    let all: [Language]

    /// Returns both, Popular and All languages, grouped
    ///
    let grouped: [[Language]]

    // MARK: - Methods

    /// Designated Initializer: will load the languages contained within the `Languages.json` file.
    ///
    override init() {
        // Parse the json file
        let raw = languagesJSON.data(using: .utf8)!
        let parsed = try! JSONSerialization.jsonObject(with: raw, options: [.mutableContainers, .mutableLeaves]) as? NSDictionary

        // Parse All + Popular: All doesn't contain Popular. Otherwise the json would have dupe data. Right?
        let parsedAll = Language.fromArray(parsed![Keys.all] as! [[String: Any]])
        let parsedPopular = Language.fromArray(parsed![Keys.popular] as! [[String: Any]])
        let merged = parsedAll + parsedPopular

        // Done!
        popular = parsedPopular
        all = merged.sorted { $0.name < $1.name }
        grouped = [popular] + [all]
    }

    /// Returns the Human Readable name for a given Language Identifier
    ///
    /// - Parameter languageId: The Identifier of the language.
    ///
    /// - Returns: A string containing the language name, or an empty string, in case it wasn't found.
    ///
    @objc func nameForLanguageWithId(_ languageId: Int) -> String {
        return find(id: languageId)?.name ?? ""
    }

    /// Returns the Language with a given Language Identifier
    ///
    /// - Parameter id: The Identifier of the language.
    ///
    /// - Returns: The language with the matching Identifier, or nil, in case it wasn't found.
    ///
    func find(id: Int) -> Language? {
        return all.first(where: { $0.id == id })
    }

    /// Returns the current device language as the corresponding WordPress.com language ID.
    /// If the language is not supported, it returns 1 (English).
    ///
    /// This is a wrapper for Objective-C, Swift code should use deviceLanguage directly.
    ///
    @objc(deviceLanguageId)
    func deviceLanguageIdNumber() -> NSNumber {
        return NSNumber(value: deviceLanguage.id)
    }

    /// Returns the slug string for the current device language.
    /// If the language is not supported, it returns "en" (English).
    ///
    /// This is a wrapper for Objective-C, Swift code should use deviceLanguage directly.
    ///
    @objc(deviceLanguageSlug)
    func deviceLanguageSlugString() -> String {
        return deviceLanguage.slug
    }

    /// Returns the current device language as the corresponding WordPress.com language.
    /// If the language is not supported, it returns English.
    ///
    var deviceLanguage: Language {
        let variants = LanguageTagVariants(string: deviceLanguageCode)
        for variant in variants {
            if let match = self.languageWithSlug(variant) {
                return match
            }
        }
        return languageWithSlug("en")!
    }

    /// Searches for a WordPress.com language that matches a language tag.
    ///
    fileprivate func languageWithSlug(_ slug: String) -> Language? {
        let search = languageCodeReplacements[slug] ?? slug

        // Use lazy evaluation so we stop filtering as soon as we got the first match
        return all.lazy.filter({ $0.slug == search }).first
    }

    /// Overrides the device language. For testing purposes only.
    ///
    @objc func _overrideDeviceLanguageCode(_ code: String) {
        deviceLanguageCode = code.lowercased()
    }

    // MARK: - Nested Classes

    /// Represents a Language supported by WordPress.com
    ///
    class Language: Equatable {
        /// Language Unique Identifier
        ///
        let id: Int

        /// Human readable Language name
        ///
        let name: String

        /// Language's Slug String
        ///
        let slug: String

        /// Localized description for the current language
        ///
        var description: String {
            return (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: slug) ?? name
        }

        /// Designated initializer. Will fail if any of the required properties is missing
        ///
        init?(dict: [String: Any]) {
            guard let unwrappedId = (dict[Keys.identifier] as? NSNumber)?.intValue,
                  let unwrappedSlug = dict[Keys.slug] as? String,
                  let unwrappedName = dict[Keys.name] as? String else {
                id = Int.min
                name = String()
                slug = String()
                return nil
            }

            id = unwrappedId
            name = unwrappedName
            slug = unwrappedSlug
        }

        /// Given an array of raw languages, will return a parsed array.
        ///
        static func fromArray(_ array: [[String: Any]] ) -> [Language] {
            return array.compactMap {
                return Language(dict: $0)
            }
        }

        static func == (lhs: Language, rhs: Language) -> Bool {
            return lhs.id == rhs.id
        }
    }

    // MARK: - Private Variables

    /// The device's current preferred language, or English if there's no preferred language.
    ///
    fileprivate lazy var deviceLanguageCode: String = {
        return NSLocale.preferredLanguages.first?.lowercased() ?? "en"
    }()

    // MARK: - Private Constants
    fileprivate let filename = "Languages"

    // (@koke 2016-04-29) I'm not sure how correct this mapping is, but it matches
    // what we do for the app translations, so they will at least be consistent
    fileprivate let languageCodeReplacements: [String: String] = [
        "zh-hans": "zh-cn",
        "zh-hant": "zh-tw"
    ]

    // MARK: - Private Nested Structures

    /// Keys used to parse the raw languages.
    ///
    fileprivate struct Keys {
        static let popular      = "popular"
        static let all          = "all"
        static let identifier   = "i"
        static let slug         = "s"
        static let name         = "n"
    }
}

/// Provides a sequence of language tags from the specified string, from more to less specific
/// For instance, "zh-Hans-HK" will yield `["zh-Hans-HK", "zh-Hans", "zh"]`
///
private struct LanguageTagVariants: Sequence {
    let string: String

    func makeIterator() -> AnyIterator<String> {
        var components = string.components(separatedBy: "-")
        return AnyIterator {
            guard !components.isEmpty else {
                return nil
            }

            let current = components.joined(separator: "-")
            components.removeLast()

            return current
        }
    }
}

private let languagesJSON = """
{
    "popular" : [
                    { "i": 1,   "s": "en",      "n": "English" },
                    { "i": 19,  "s": "es",      "n": "Español" },
                    { "i": 438, "s": "pt-br",   "n": "Português do Brasil" },
                    { "i": 15,  "s": "de",      "n": "Deutsch" },
                    { "i": 24,  "s": "fr",      "n": "Français" },
                    { "i": 29,  "s": "he",      "n": "עברית" },
                    { "i": 36,  "s": "ja",      "n": "日本語" },
                    { "i": 35,  "s": "it",      "n": "Italiano" },
                    { "i": 49,  "s": "nl",      "n": "Nederlands" },
                    { "i": 62,  "s": "ru",      "n": "Русский" },
                    { "i": 78,  "s": "tr",      "n": "Türkçe" },
                    { "i": 33,  "s": "id",      "n": "Bahasa Indonesia" },
                    { "i": 449, "s": "zh-cn",   "n": "中文(简体)" },
                    { "i": 452, "s": "zh-tw",   "n": "中文(繁體)" },
                    { "i": 40,  "s": "ko",      "n": "한국어" }
                ],
    "all" :     [
                    { "i": 2,   "s": "af",      "n": "Afrikaans" },
                    { "i": 418, "s": "als",     "n": "Alemannisch" },
                    { "i": 481, "s": "am",      "n": "Amharic" },
                    { "i": 3,   "s": "ar",      "n": "العربية" },
                    { "i": 419, "s": "arc",     "n": "ܕܥܒܪܸܝܛ" },
                    { "i": 4,   "s": "as",      "n": "অসমীয়া" },
                    { "i": 420, "s": "ast",     "n": "Asturianu" },
                    { "i": 421, "s": "av",      "n": "Авар" },
                    { "i": 422, "s": "ay",      "n": "Aymar" },
                    { "i": 79,  "s": "az",      "n": "Azərbaycan" },
                    { "i": 423, "s": "ba",      "n": "Башҡорт" },
                    { "i": 5,   "s": "be",      "n": "Беларуская" },
                    { "i": 6,   "s": "bg",      "n": "Български" },
                    { "i": 7,   "s": "bm",      "n": "Bamanankan" },
                    { "i": 8,   "s": "bn",      "n": "বাংলা" },
                    { "i": 9,   "s": "bo",      "n": "བོད་ཡིག" },
                    { "i": 424, "s": "br",      "n": "Brezhoneg" },
                    { "i": 454, "s": "bs",      "n": "Bosanski" },
                    { "i": 10,  "s": "ca",      "n": "Català" },
                    { "i": 425, "s": "ce",      "n": "Нохчийн" },
                    { "i": 11,  "s": "cs",      "n": "Česky" },
                    { "i": 12,  "s": "csb",     "n": "Kaszëbsczi" },
                    { "i": 426, "s": "cv",      "n": "Чӑваш" },
                    { "i": 13,  "s": "cy",      "n": "Cymraeg" },
                    { "i": 14,  "s": "da",      "n": "Dansk" },
                    { "i": 427, "s": "dv",      "n": "Divehi" },
                    { "i": 16,  "s": "dz",      "n": "ཇོང་ཁ" },
                    { "i": 17,  "s": "el",      "n": "Ελληνικά" },
                    { "i": 468, "s": "el-po",   "n": "Greek-polytonic" },
                    { "i": 18,  "s": "eo",      "n": "Esperanto" },
                    { "i": 20,  "s": "et",      "n": "Eesti" },
                    { "i": 429, "s": "eu",      "n": "Euskara" },
                    { "i": 21,  "s": "fa",      "n": "فارسی" },
                    { "i": 22,  "s": "fi",      "n": "Suomi" },
                    { "i": 473, "s": "fil",     "n": "Filipino" },
                    { "i": 23,  "s": "fo",      "n": "Føroyskt" },
                    { "i": 478, "s": "fr-be",   "n": "Français de Belgique" },
                    { "i": 475, "s": "fr-ca",   "n": "Français (Canada)" },
                    { "i": 474, "s": "fr-ch",   "n": "Français de Suisse" },
                    { "i": 25,  "s": "fur",     "n": "Furlan" },
                    { "i": 26,  "s": "fy",      "n": "Frysk" },
                    { "i": 27,  "s": "ga",      "n": "Gaeilge" },
                    { "i": 476, "s": "gd",      "n": "Gàidhlig" },
                    { "i": 457, "s": "gl",      "n": "Galego" },
                    { "i": 430, "s": "gn",      "n": "Avañeẽ" },
                    { "i": 28,  "s": "gu",      "n": "ગુજરાતી" },
                    { "i": 30,  "s": "hi",      "n": "हिन्दी" },
                    { "i": 431, "s": "hr",      "n": "Hrvatski" },
                    { "i": 31,  "s": "hu",      "n": "Magyar" },
                    { "i": 467, "s": "hy",      "n": "Armenian" },
                    { "i": 32,  "s": "ia",      "n": "Interlingua" },
                    { "i": 432, "s": "ii",      "n": "ꆇꉙ" },
                    { "i": 469, "s": "ilo",     "n": "Ilokano" },
                    { "i": 34,  "s": "is",      "n": "Íslenska" },
                    { "i": 37,  "s": "ka",      "n": "ქართული" },
                    { "i": 462, "s": "kk",      "n": "Қазақ тілі" },
                    { "i": 38,  "s": "km",      "n": "ភាសាខ្មែរ" },
                    { "i": 39,  "s": "kn",      "n": "ಕನ್ನಡ" },
                    { "i": 433, "s": "ks",      "n": "कश्मीरी - (كشميري)" },
                    { "i": 41,  "s": "ku",      "n": "Kurdî / كوردي" },
                    { "i": 434, "s": "kv",      "n": "Коми" },
                    { "i": 479, "s": "ky",      "n": "кыргыз тили" },
                    { "i": 42,  "s": "la",      "n": "Latina" },
                    { "i": 43,  "s": "li",      "n": "Limburgs" },
                    { "i": 44,  "s": "lo",      "n": "ລາວ" },
                    { "i": 45,  "s": "lt",      "n": "Lietuvių" },
                    { "i": 453, "s": "lv",      "n": "Latviešu valoda" },
                    { "i": 435, "s": "mk",      "n": "Македонски" },
                    { "i": 46,  "s": "ml",      "n": "മലയാളം" },
                    { "i": 472, "s": "mn",      "n": "монгол хэл" },
                    { "i": 461, "s": "mr",      "n": "मराठी Marāṭhī" },
                    { "i": 47,  "s": "ms",      "n": "Bahasa Melayu" },
                    { "i": 465, "s": "mt",      "n": "Malti" },
                    { "i": 464, "s": "mwl",     "n": "Mirandés" },
                    { "i": 436, "s": "nah",     "n": "Nahuatl" },
                    { "i": 437, "s": "nap",     "n": "Nnapulitano" },
                    { "i": 48,  "s": "nds",     "n": "Plattdüütsch" },
                    { "i": 456, "s": "ne",      "n": "Nepali" },
                    { "i": 50,  "s": "nn",      "n": "Norsk (nynorsk)" },
                    { "i": 51,  "s": "no",      "n": "Norsk (bokmål)" },
                    { "i": 52,  "s": "non",     "n": "Norrǿna" },
                    { "i": 53,  "s": "nv",      "n": "Diné bizaad" },
                    { "i": 54,  "s": "oc",      "n": "Occitan" },
                    { "i": 55,  "s": "or",      "n": "ଓଡ଼ିଆ" },
                    { "i": 56,  "s": "os",      "n": "Иронау" },
                    { "i": 57,  "s": "pa",      "n": "ਪੰਜਾਬੀ" },
                    { "i": 58,  "s": "pl",      "n": "Polski" },
                    { "i": 59,  "s": "ps",      "n": "پښتو" },
                    { "i": 60,  "s": "pt",      "n": "Português" },
                    { "i": 439, "s": "qu",      "n": "Runa Simi" },
                    { "i": 61,  "s": "ro",      "n": "Română" },
                    { "i": 483, "s": "rup",     "n": "Armãneashce" },
                    { "i": 63,  "s": "sc",      "n": "Sardu" },
                    { "i": 440, "s": "sd",      "n": "سنڌي" },
                    { "i": 471, "s": "si",      "n": "Sinhala" },
                    { "i": 64,  "s": "sk",      "n": "Slovenčina" },
                    { "i": 65,  "s": "sl",      "n": "Slovenščina" },
                    { "i": 459, "s": "so",      "n": "Somali" },
                    { "i": 66,  "s": "sq",      "n": "Shqip" },
                    { "i": 67,  "s": "sr",      "n": "Српски / Srpski" },
                    { "i": 441, "s": "su",      "n": "Basa Sunda" },
                    { "i": 68,  "s": "sv",      "n": "Svenska" },
                    { "i": 69,  "s": "ta",      "n": "தமிழ்" },
                    { "i": 70,  "s": "te",      "n": "తెలుగు" },
                    { "i": 71,  "s": "th",      "n": "ไทย" },
                    { "i": 480, "s": "tir",     "n": "Tigrigna" },
                    { "i": 455, "s": "tl",      "n": "Tagalog" },
                    { "i": 72,  "s": "tt",      "n": "Tatarça" },
                    { "i": 442, "s": "ty",      "n": "Reo Mā`ohi" },
                    { "i": 443, "s": "udm",     "n": "Удмурт" },
                    { "i": 444, "s": "ug",      "n": "Uyghur"},
                    { "i": 73,  "s": "uk",      "n": "Українська" },
                    { "i": 74,  "s": "ur",      "n": "اردو" },
                    { "i": 458, "s": "uz",      "n": "Uzbek" },
                    { "i": 463, "s": "va",      "n": "valencià" },
                    { "i": 445, "s": "vec",     "n": "Vèneto" },
                    { "i": 446, "s": "vi",      "n": "Tiếng Việt" },
                    { "i": 75,  "s": "wa",      "n": "Walon" },
                    { "i": 447, "s": "xal",     "n": "Хальмг" },
                    { "i": 76,  "s": "yi",      "n": "ייִדיש" },
                    { "i": 477, "s": "yo",      "n": "èdè Yorùbá" },
                    { "i": 448, "s": "za",      "n": "Zhuang (Cuengh)" },
                    { "i": 77,  "s": "zh",      "n": "中文" },
                    { "i": 450, "s": "zh-hk",   "n": "中文(繁體)" },
                    { "i": 451, "s": "zh-sg",   "n": "中文(简体)" }
                 ]
}
"""
