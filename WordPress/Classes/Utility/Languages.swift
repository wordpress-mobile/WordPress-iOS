import Foundation



/// This helper class allows us to map WordPress.com LanguageID's into human readable language strings.
///
class WordPressComLanguageDatabase : NSObject
{
    // MARK: - Public Properties

    /// Languages considered 'popular'
    ///
    let popular : [Language]

    /// Every supported language
    ///
    let all : [Language]

    /// Returns both, Popular and All languages, grouped
    ///
    let grouped : [[Language]]


    // MARK: - Public Methods

    /// Designated Initializer: will load the languages contained within the `Languages.json` file.
    ///
    override init() {
        // Parse the json file
        let path = NSBundle.mainBundle().pathForResource(filename, ofType: "json")
        let raw = NSData(contentsOfFile: path!)!
        let parsed = try! NSJSONSerialization.JSONObjectWithData(raw, options: [.MutableContainers, .MutableLeaves]) as? NSDictionary

        // Parse All + Popular: All doesn't contain Popular. Otherwise the json would have dupe data. Right?
        let parsedAll = Language.fromArray(parsed!.arrayForKey(Keys.all) as! [NSDictionary])
        let parsedPopular = Language.fromArray(parsed!.arrayForKey(Keys.popular) as! [NSDictionary])
        let merged = parsedAll + parsedPopular

        // Done!
        popular = parsedPopular
        all = merged.sort { $0.name < $1.name }
        grouped = [popular] + [all]
    }


    /// Returns the Human Readable name for a given Language Identifier
    ///
    /// - Parameter languageId: The Identifier of the language.
    ///
    /// - Returns: A string containing the language name, or an empty string, in case it wasn't found.
    ///
    func nameForLanguageWithId(languageId: Int) -> String {
        for language in all {
            if language.id == languageId {
                return language.name
            }
        }

        return String()
    }

    /// Returns the current device language as the corresponding WordPress.com language ID.
    /// If the language is not supported, it returns 1 (English).
    ///
    /// This is a wrapper for Objective-C, Swift code should use deviceLanguage directly.
    ///
    @objc(deviceLanguageId)
    func deviceLanguageIdNumber() -> NSNumber {
        return deviceLanguage.id
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
    private func languageWithSlug(slug: String) -> Language? {
        let search = languageCodeReplacements[slug] ?? slug

        // Use lazy evaluation so we stop filtering as soon as we got the first match
        return all.lazy.filter({ $0.slug == search }).first
    }

    /// Overrides the device language. For testing purposes only.
    ///
    func _overrideDeviceLanguageCode(code: String) {
        deviceLanguageCode = code.lowercaseString
    }

    // MARK: - Public Nested Classes

    /// Represents a Language supported by WordPress.com
    ///
    class Language
    {
        /// Language Unique Identifier
        ///
        let id : Int

        /// Human readable Language name
        ///
        let name : String

        /// Language's Slug String
        ///
        let slug : String

        /// Localized description for the current language
        ///
        var description : String {
            return NSLocale.currentLocale().displayNameForKey(NSLocaleIdentifier, value: slug) ?? name
        }



        /// Designated initializer. Will fail if any of the required properties is missing
        ///
        init?(dict : NSDictionary) {
            guard let unwrappedId = dict.numberForKey(Keys.identifier)?.integerValue,
                        unwrappedSlug = dict.stringForKey(Keys.slug),
                        unwrappedName = dict.stringForKey(Keys.name) else
            {
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
        static func fromArray(array : [NSDictionary]) -> [Language] {
            return array.flatMap {
                return Language(dict: $0)
            }
        }
    }

    // MARK: - Private Variables

    /// The device's current preferred language, or English if there's no preferred language.
    ///
    private lazy var deviceLanguageCode: String = {
        return NSLocale.preferredLanguages().first?.lowercaseString ?? "en"
    }()


    // MARK: - Private Constants
    private let filename = "Languages"

    // (@koke 2016-04-29) I'm not sure how correct this mapping is, but it matches
    // what we do for the app translations, so they will at least be consistent
    private let languageCodeReplacements: [String: String] = [
        "zh-hans": "zh-cn",
        "zh-hant": "zh-tw"
    ]


    // MARK: - Private Nested Structures

    /// Keys used to parse the raw languages.
    ///
    private struct Keys
    {
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
private struct LanguageTagVariants: SequenceType {
    let string: String

    func generate() -> AnyGenerator<String> {
        var components = string.componentsSeparatedByString("-")
        return AnyGenerator {
            guard !components.isEmpty else {
                return nil
            }

            let current = components.joinWithSeparator("-")
            components.removeLast()

            return current
        }
    }
}
