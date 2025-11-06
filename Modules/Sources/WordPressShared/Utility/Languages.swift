import Foundation

/// This helper class allows us to map WordPress.com LanguageID's into human readable language strings.
///
public struct WordPressComLanguageDatabase {

    public static let shared = WordPressComLanguageDatabase()

    // MARK: - Public Properties

    /// Languages considered 'popular'
    ///
    public let popular: [WPComLanguage]

    /// Every supported language
    ///
    public let all: [WPComLanguage]

    /// Allow mocking the device language code for testing purposes
    private let _deviceLanguageCode: String?

    // MARK: - Public Methods

    /// Designated Initializer: will load the languages contained within the `Languages.json` file.
    ///
    private init() {
        // Parse the json file
        let path = Bundle.wordPressSharedBundle.path(forResource: "Languages", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let bundle = try! JSONDecoder().decode(WPComLanguageBundle.self, from: data)

        self.popular = bundle.popular
        self.all = bundle.all
        self._deviceLanguageCode = nil
    }

    /// Specifically marked internal for used by test code
    internal init(deviceLanguageCode: String) {
        // Parse the json file
        let path = Bundle.wordPressSharedBundle.path(forResource: "Languages", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let bundle = try! JSONDecoder().decode(WPComLanguageBundle.self, from: data)

        self.popular = bundle.popular
        self.all = bundle.all
        self._deviceLanguageCode = deviceLanguageCode.lowercased()
    }

    /// Returns the Human Readable name for a given Language Identifier
    ///
    /// - Parameter languageId: The Identifier of the language.
    ///
    /// - Returns: A string containing the language name, or an empty string, in case it wasn't found.
    ///
    public func nameForLanguageWithId(_ languageId: Int) -> String {
        return find(id: languageId)?.name ?? ""
    }

    /// Returns the Language with a given Language Identifier
    ///
    /// - Parameter id: The Identifier of the language.
    ///
    /// - Returns: The language with the matching Identifier, or nil, in case it wasn't found.
    ///
    public func find(id: Int) -> WPComLanguage? {
        return all.first(where: { $0.id == id })
    }

    /// Returns the current device language as the corresponding WordPress.com language.
    /// If the language is not supported, it returns English.
    ///
    public var deviceLanguage: WPComLanguage {
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
    fileprivate func languageWithSlug(_ slug: String) -> WPComLanguage? {
        let search = languageCodeReplacements[slug] ?? slug
        return all.first { $0.slug == search }
    }

    // MARK: - Private Variables

    /// The device's current preferred language, or English if there's no preferred language.
    ///
    /// Specifically marked internal for used by test code
    internal var deviceLanguageCode: String {

        // Return the mocked language code, if set
        if let _deviceLanguageCode {
            return _deviceLanguageCode
        }

        guard let preferredLanguage = Locale.preferredLanguages.first else {
            return "en"
        }

        return preferredLanguage.lowercased()
    }

    // (@koke 2016-04-29) I'm not sure how correct this mapping is, but it matches
    // what we do for the app translations, so they will at least be consistent
    fileprivate let languageCodeReplacements: [String: String] = [
        "zh-hans": "zh-cn",
        "zh-hant": "zh-tw"
    ]
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

// MARK: - Public Nested Classes

public struct WPComLanguageBundle: Codable {
    let popular: [WPComLanguage]
    let others: [WPComLanguage]

    enum CodingKeys: String, CodingKey {
        case popular = "popular"
        case others = "all"
    }

    var all: [WPComLanguage] {
        (popular + others).sorted { $0.name < $1.name }
    }
}

/// Represents a Language supported by WordPress.com
///
public struct WPComLanguage: Codable, Equatable {

    enum CodingKeys: String, CodingKey {
        case id = "i"
        case name = "n"
        case slug = "s"
    }

    /// Language Unique Identifier
    ///
    public let id: Int

    /// Human readable Language name
    ///
    public let name: String

    /// Language's Slug String
    ///
    public let slug: String

    /// Localized description for the current language
    ///
    public var description: String {
        return (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: slug) ?? name
    }
}
