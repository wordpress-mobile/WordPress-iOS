import Foundation



/// This helper class allows us to map WordPress.com LanguageID's into human readable language strings.
///
class Languages : NSObject
{
    // MARK: - Public Properties
    
    /// Languages considered 'popular'
    ///
    let popular : [Language]
    
    /// Every supported language
    ///
    let all : [Language]
    
    
    
    // MARK: - Public Methods
    
    /// Designated Initializer: will load the languages contained within the `Languages.json` file.
    ///
    override init() {
        let path = NSBundle.mainBundle().pathForResource(filename, ofType: "json")
        let data = NSData(contentsOfFile: path!)!
        let options : NSJSONReadingOptions = [.MutableContainers, .MutableLeaves]
        let parsed = try! NSJSONSerialization.JSONObjectWithData(data, options: options) as? NSDictionary
        
        popular = Language.fromArray(parsed!.arrayForKey(Keys.all) as! [NSDictionary])
        all = Language.fromArray(parsed!.arrayForKey(Keys.popular) as! [NSDictionary])
    }
    
    
    
    // MARK: - Public Nested Classes
    
    /// Represents a Language, which allows us to deal with WordPress.com settings
    ///
    class Language
    {
        /// Human readable Language name
        ///
        let name : String!
        
        /// Language's Slug String
        ///
        let slug : String!
        
        /// Language's numeric code
        ///
        let value : Int!
        
        
        
        /// Designated initializer. Will fail if any of the required properties is missing
        ///
        init?(dict : NSDictionary) {
            slug = dict.stringForKey(Keys.slug)
            name = dict.stringForKey(Keys.name)
            value = dict.numberForKey(Keys.value)?.integerValue
            
            guard slug != nil && name != nil && value != nil else {
                return nil
            }
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
        static let popular  = "popular"
        static let all      = "all"
        static let slug     = "s"
        static let name     = "n"
        static let value    = "v"
    }
}
