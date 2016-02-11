import Foundation



/// This helper class allows us to map WordPress.com LanguageID's into human readable language strings.
///
class Languages : NSObject
{
    // MARK: - Public Properties
    
    /// Shared Languages Instance
    ///
    static let sharedInstance = Languages()
    
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
    /// - Parameters:
    ///     - languageId: The Identifier of the language.
    ///
    /// - Returns: A string containing the language name, or an empty string, in case it wasn't found.
    ///
    func nameForLanguageWithId(languageId: Int) -> String {
        for language in all {
            if language.languageId == languageId {
                return language.name
            }
        }
        
        return String()
    }
    
    
    // MARK: - Public Nested Classes
    
    /// Represents a Language, which allows us to deal with WordPress.com settings
    ///
    class Language
    {
        /// Language Unique Identifier
        ///
        let languageId : NSNumber
        
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
            guard let unwrappedLanguageId = dict.numberForKey(Keys.identifier)?.integerValue,
                        unwrappedSlug = dict.stringForKey(Keys.slug),
                        unwrappedName = dict.stringForKey(Keys.name) else
            {
                languageId = Int.min
                name = String()
                slug = String()
                return nil
            }
            
            languageId = unwrappedLanguageId
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
    
    
    
    // MARK: - Private Constants
    private let filename = "Languages"
    
    
    
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
