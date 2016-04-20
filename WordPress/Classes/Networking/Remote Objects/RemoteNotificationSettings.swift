import Foundation


/**
*  @class           RemoteNotificationSettings
*  @brief           The goal of this class is to parse Notification Settings data from the backend, and structure it
*                   in a meaningful way. Notification Settings come in three different flavors:
*                   
*                   -   "Our Own" Blog Settings
*                   -   "Third Party" Site Settings
*                   -   WordPress.com Settings
*
*                   Each one of the possible channels may post notifications via different streams: Email, 
*                   Push Notifications, and Timeline.
*/

public class RemoteNotificationSettings
{
    /**
    *  @details Represents the Channel to which the current settings are associated.
    */
    public let channel : Channel
    
    /**
    *  @details Contains an array of the available Notification Streams.
    */
    public let streams : [Stream]
    
    
    
    /**
    *  @enum        Channel
    *  @brief       Represents a communication channel that may post notifications to the user.
    */
    public enum Channel : Equatable {
        case Blog(blogId: Int)
        case Other
        case WordPressCom
    }
    
    
    /**
    *  @class       Stream
    *  @brief       Contains the Notification Settings for a specific communications stream.
    */
    public class Stream {
        public var kind         : Kind
        public var preferences  : [String : Bool]?
        
        
        /**
        *  @enum    Stream.Kind
        *  @brief   Enumerates all of the possible Stream Kinds
        */
        public enum Kind : String {
            case Timeline       = "timeline"
            case Email          = "email"
            case Device         = "device"
            
            static let allValues = [ Timeline, Email, Device ]
        }
        
        
        /**
        *  @details Private Designated Initializer
        *  @param   kind            The Kind of stream we're currently dealing with
        *  @param   preferences     Raw remote preferences, retrieved from the backend
        */
        private init(kind: Kind, preferences: NSDictionary?) {
            self.kind           = kind
            self.preferences    = filterNonBooleanEntries(preferences)
        }

        
        /**
        *  @brief   Helper method that will filter out non boolean entries, and return a native Swift collection.
        *  @param   dictionary      NextStep Dictionary containing raw values
        *  @return                  A native Swift dictionary, containing only the Boolean entries
        */
        private func filterNonBooleanEntries(dictionary: NSDictionary?) -> [String : Bool] {
            var filtered = [String : Bool]()
            if dictionary == nil {
                return filtered
            }
            
            for (key, value) in dictionary! {
                if let stringKey = key   as? String,
                   let boolValue = value as? Bool
                {
                    // NSNumbers might get converted to Bool anyways
                    if value === kCFBooleanFalse || value === kCFBooleanTrue {
                        filtered[stringKey] = boolValue
                    }
                }
            }
            
            return filtered
        }
        
        
        /**
        *  @brief   Parser method that will convert a raw dictionary of stream settings into Swift Native objects.
        *  @param   dictionary      NextStep Dictionary containing raw Stream Preferences
        *  @return                  A native Swift array containing Stream entities
        */
        private static func fromDictionary(dictionary: NSDictionary?) -> [Stream] {
            var parsed = [Stream]()
            
            for kind in Kind.allValues {
                if let preferences = dictionary?[kind.rawValue] as? NSDictionary {
                    parsed.append(Stream(kind: kind, preferences: preferences))
                }
            }
            
            return parsed
        }
    }
    
    
    /**
    *  @details     Private Designated Initializer
    *  @param       channel         The communications channel that uses the current settings
    *  @param       settings        Raw dictionary containing the remote settings response
    */
    private init(channel: Channel, settings: NSDictionary?) {
        self.channel = channel
        self.streams = Stream.fromDictionary(settings)
    }
    
    
    /**
    *  @details     Private Designated Initializer
    *  @param       wpcomSettings   Dictionary containing the collection of WordPress.com Settings
    */
    private init(wpcomSettings: NSDictionary?) {
        // WordPress.com is a special scenario: It contains just one (unspecified) stream: Email
        self.channel = Channel.WordPressCom
        self.streams = [ Stream(kind: .Email, preferences: wpcomSettings) ]
    }
    
    
    /**
    *  @details     Private Convenience Initializer
    *  @param       blogSettings    Dictionary containing the collection of settings for a single blog
    */
    private convenience init(blogSettings: NSDictionary?) {
        let blogId = blogSettings?["blog_id"] as? Int ?? Int.max
        self.init(channel: Channel.Blog(blogId: blogId), settings: blogSettings)
    }
    
    
    /**
    *  @details     Private Convenience Initializer
    *  @param       otherSettings   Dictionary containing the collection of "Other Settings"
    */
    private convenience init(otherSettings: NSDictionary?) {
        self.init(channel: Channel.Other, settings: otherSettings)
    }
    
    
    
    /**
    *  @details     Static Helper that will parse all of the Remote Settings, into a collection of
    *               Swift Native RemoteNotificationSettings objects
    *  @param       dictionary      Dictionary containing the remote Settings response
    *  @returns                     An array of RemoteNotificationSettings objects
    */
    public static func fromDictionary(dictionary: NSDictionary?) -> [RemoteNotificationSettings] {
        var parsed = [RemoteNotificationSettings]()
        
        if let rawBlogs = dictionary?["blogs"] as? [NSDictionary] {
            for rawBlog in rawBlogs {
                let parsedBlog = RemoteNotificationSettings(blogSettings: rawBlog)
                parsed.append(parsedBlog)
            }
        }
        
        let other = RemoteNotificationSettings(otherSettings: dictionary?["other"] as? NSDictionary)
        parsed.append(other)
        
        let wpcom = RemoteNotificationSettings(wpcomSettings: dictionary?["wpcom"] as? NSDictionary)
        parsed.append(wpcom)
        
        return parsed
    }
}



/**
*  @brief           RemoteNotificationSettings.Channel Equatable Implementation
*  @details         Swift requires this method to be implemented globally. Sorry about that!
*
*  @param           lhs         Left Hand Side Channel
*  @param           rhs         Right Hand Side Channel
*  @returns                     A boolean indicating whether two channels are equal. Or not!
*/
public func ==(lhs: RemoteNotificationSettings.Channel, rhs: RemoteNotificationSettings.Channel) -> Bool
{
    switch (lhs, rhs) {
    case (let .Blog(firstBlogId), let .Blog(secondBlogId)) where firstBlogId == secondBlogId:
        return true
    case (.Other, .Other):
        return true
    case (.WordPressCom, .WordPressCom):
        return true
    default:
        return false
    }
}
