import Foundation



/// This helper class allows us to map WordPress.com LanguageID's into human readable language strings.
///
class WordPressComLanguageDatabase: NSObject {
    // MARK: - Public Properties

    /// Languages considered 'popular'
    ///
    let popular: [Language]

    /// Every supported language
    ///
    let all: [Language]

    /// Returns both, Popular and All languages, grouped
    ///
    let grouped: [[Language]]


    // MARK: - Public Methods

    /// Designated Initializer: will load the languages contained within the `Languages.json` file.
    ///
    override init() {
        // Parse the json file
        let path = Bundle.main.path(forResource: filename, ofType: "json")
        let raw = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let parsed = try! JSONSerialization.jsonObject(with: raw, options: [.mutableContainers, .mutableLeaves]) as? NSDictionary

        // Parse All + Popular: All doesn't contain Popular. Otherwise the json would have dupe data. Right?
        let parsedAll = Language.fromArray(parsed!.array(forKey: Keys.all) as! [NSDictionary])
        let parsedPopular = Language.fromArray(parsed!.array(forKey: Keys.popular) as! [NSDictionary])
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
    func nameForLanguageWithId(_ languageId: Int) -> String {
        return find(id: languageId)?.name ?? ""
    }

    /// Returns the Language with a given Language Identifier
    ///
    /// - Parameter languageId: The Identifier of the language.
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
    func _overrideDeviceLanguageCode(_ code: String) {
        deviceLanguageCode = code.lowercased()
    }

    // MARK: - Public Nested Classes

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
        init?(dict: NSDictionary) {
            guard let unwrappedId = dict.number(forKey: Keys.identifier)?.intValue,
                        let unwrappedSlug = dict.string(forKey: Keys.slug),
                        let unwrappedName = dict.string(forKey: Keys.name) else {
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
        static func fromArray(_ array: [NSDictionary]) -> [Language] {
            return array.flatMap {
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
