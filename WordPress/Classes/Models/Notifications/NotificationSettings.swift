import Foundation


/**
*  @class           NotificationSettings
*  @brief           The goal of this class is to encapsulate all of the User's Notification Settings in a generic way.
*                   Settings are grouped into different Channels, and each channel may contain different streams.
*/

public class NotificationSettings
{
    public let channel  : Channel
    public let streams  : [Stream]
    public let blog     : Blog?
    
    
    /**
    *  @details     Designated Initializer
    *  @param       channel     The related Notifications Channel
    *  @param       streams     An array of all of the involved streams
    */
    public init(channel: Channel, streams: [Stream], blog: Blog?) {
        self.channel = channel
        self.streams = streams
        self.blog    = blog
    }
    
    
    /**
    *  @details Returns the localized description for any given preference key
    */
    public func localizedDescription(preferenceKey: String) -> String {
        return localizedDescriptionMap[preferenceKey] ?? String()
    }
    
    
    /**
    *  @details Returns an array of the sorted Preference Keys
    */
    public func sortedPreferenceKeys() -> [String] {
        switch channel {
        case let .Blog(blogId):
            return blogPreferenceKeys
        case .Other:
            return otherPreferenceKeys
        case .WordPressCom:
            return wpcomPreferenceKeys
        }
    }
    

    /**
    *  @enum        Channel
    *  @brief       Represents a communication channel that may post notifications to the user.
    */
    public enum Channel : Equatable {
        case Blog(blogId: Int)
        case Other
        case WordPressCom
        
        
        /**
        *  @details Returns the localized description of the current enum value
        */
        func description() -> String {
            switch self {
            case .Blog:
                return NSLocalizedString("WordPress Blog", comment: "Notification Settings Channel")
            case .Other:
                return NSLocalizedString("Comments on Other Sites", comment: "Notification Settings Channel")
            case .WordPressCom:
                return NSLocalizedString("Updates from WordPress.com", comment: "Notification Settings Channel")
            }
        }
    }
    
    
    /**
    *  @class       Stream
    *  @brief       Contains the Notification Settings for a specific communications stream.
    */
    public class Stream {
        public var kind         : Kind
        public var preferences  : [String : Bool]?
        
        
        /**
        *  @details Designated Initializer
        *  @param   kind            The Kind of stream we're currently dealing with
        *  @param   preferences     Raw remote preferences, retrieved from the backend
        */
        public init(kind: String, preferences: [String : Bool]?) {
            self.kind           = Kind(rawValue: kind) ?? .Email
            self.preferences    = preferences
        }
        
        
        /**
        *  @enum    Stream.Kind
        *  @brief   Enumerates all of the possible Stream Kinds
        */
        public enum Kind : String {
            case Timeline       = "timeline"
            case Email          = "email"
            case Device         = "device"
            
            
            /**
            *  @details Returns the localized description of the current enum value
            */
            func description() -> String {
                switch self {
                case .Timeline:
                    return NSLocalizedString("Notifications Tab", comment: "WordPress.com Notifications Timeline")
                case .Email:
                    return NSLocalizedString("Email", comment: "Email Notifications Channel")
                case .Device:
                    return NSLocalizedString("Mobile Notifications", comment: "Mobile Push Notifications")
                }
            }
            
            static let allValues = [ Timeline, Email, Device ]
        }
    }
    
    // MARK: - Private Properties
    private let blogPreferenceKeys  = ["new_comment", "comment_like", "post_like", "follow", "achievement", "mentions"]
    private let otherPreferenceKeys = ["comment_like", "comment_reply"]
    private let wpcomPreferenceKeys = ["news", "recommendation", "promotion", "digest"]
    
    // MARK: - Localized Setting Descriptions
    private let localizedDescriptionMap = [
        "new_comment" 	 : NSLocalizedString("New Comments",             comment: "Notifications Settings"),
        "comment_like" 	 : NSLocalizedString("Comment Likes",            comment: "Notifications Settings"),
        "post_like" 	 : NSLocalizedString("Post Likes",               comment: "Notifications Settings"),
        "follow"      	 : NSLocalizedString("Follows",                  comment: "Notifications Settings"),
        "achievement" 	 : NSLocalizedString("Achievements",             comment: "Notifications Settings"),
        "mentions" 		 : NSLocalizedString("Mentions",                 comment: "Notifications Settings"),
        "comment_reply"  : NSLocalizedString("Replies to your comments", comment: "Notifications Settings"),
        "news"			 : NSLocalizedString("News",                     comment: "Notifications Settings"),
        "recommendation" : NSLocalizedString("Recomendations",           comment: "Notifications Settings"),
        "promotion"		 : NSLocalizedString("Promotions",               comment: "Notifications Settings"),
        "digest"		 : NSLocalizedString("Digest",                   comment: "Notifications Settings")
    ]
}



/**
*  @brief           NotificationSettings.Channel Equatable Implementation
*  @details         Swift requires this method to be implemented globally. Sorry about that!
*
*  @param           lhs         Left Hand Side Channel
*  @param           rhs         Right Hand Side Channel
*  @returns                     A boolean indicating whether two channels are equal. Or not!
*/
public func ==(first: NotificationSettings.Channel, second: NotificationSettings.Channel) -> Bool
{
    switch (first, second) {
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
