import Foundation


/**
*  @class           NotificationSettings
*  @brief           The goal of this class is to encapsulate all of the User's Notification Settings in a generic way.
*                   Settings are grouped into different Channels. A Channel is considered anything that might 
*                   produce Notifications: a WordPress blog, Third Party Sites or WordPress.com.
*                   Each channel may support different streams, such as: Email + Push Notifications + Timeline.
*/

public class NotificationSettings
{
    /**
    *  @details Represents the Channel to which the current settings are associated.
    */
    public let channel  : Channel
    
    /**
    *  @details Contains an array of the available Notification Streams.
    */
    public let streams  : [Stream]
    
    /**
    *  @details Maps to the associated blog, if any.
    */
    public let blog     : Blog?
    
    
    
    /**
    *  @details     Designated Initializer
    *  @param       channel     The related Notifications Channel
    *  @param       streams     An array of all of the involved streams
    *  @param       blog        The associated blog, if any
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
        return Keys.localizedDescriptionMap[preferenceKey] ?? String()
    }
    
    /**
    *  @details Returns the details for a given preference key
    */
    public func localizedDetails(preferenceKey: String) -> String? {
        return Keys.localizedDetailsMap[preferenceKey]
    }
    
    
    /**
    *  @details Returns an array of the sorted Preference Keys
    */
    public func sortedPreferenceKeys(stream: Stream?) -> [String] {
        switch channel {
        case .Blog(_):
            // Email Streams require a special treatment
            return stream?.kind == .Email ? blogEmailPreferenceKeys : blogPreferenceKeys
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
                return NSLocalizedString("WordPress Blog", comment: "Settings for a Wordpress Blog")
            case .Other:
                return NSLocalizedString("Comments on Other Sites", comment: "Notification Settings Channel")
            case .WordPressCom:
                return NSLocalizedString("Email from WordPress.com", comment: "Notification Settings Channel")
            }
        }
    }
    
    
    /**
    *  @class       Stream
    *  @brief       Contains the Notification Settings collection for a specific communications stream.
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
                    return NSLocalizedString("Push Notifications", comment: "Mobile Push Notifications")
                }
            }
            
            static let allValues = [ Timeline, Email, Device ]
        }
    }
    
    // MARK: - Private Properties
    private let blogPreferenceKeys      = [Keys.commentAdded, Keys.commentLiked, Keys.postLiked, Keys.follower, Keys.achievement, Keys.mention]
    private let blogEmailPreferenceKeys = [Keys.commentAdded, Keys.commentLiked, Keys.postLiked, Keys.follower, Keys.mention]
    private let otherPreferenceKeys     = [Keys.commentLiked, Keys.commentReplied]
    private let wpcomPreferenceKeys     = [Keys.marketing, Keys.research, Keys.community]
    
    // MARK: - Setting Keys
    private struct Keys
    {
        static let commentAdded     = "new_comment"
        static let commentLiked     = "comment_like"
        static let commentReplied   = "comment_reply"
        static let postLiked        = "post_like"
        static let follower         = "follow"
        static let achievement      = "achievement"
        static let mention          = "mentions"
        static let marketing        = "marketing"
        static let research         = "research"
        static let community        = "community"
        
        static let localizedDescriptionMap = [
            commentAdded    : NSLocalizedString("Comments on my site",
                                comment: "Setting: indicates if New Comments will be notified"),
            commentLiked    : NSLocalizedString("Likes on my comments",
                                comment: "Setting: indicates if Comment Likes will be notified"),
            postLiked       : NSLocalizedString("Likes on my posts",
                                comment: "Setting: indicates if Replies to your comments will be notified"),
            follower        : NSLocalizedString("Site follows",
                                comment: "Setting: indicates if New Follows will be notified"),
            achievement     : NSLocalizedString("Site achievements",
                                comment: "Setting: indicates if Achievements will be notified"),
            mention         : NSLocalizedString("Username mentions",
                                comment: "Setting: indicates if Mentions will be notified"),
            commentReplied  : NSLocalizedString("Replies to your comments",
                                comment: "Setting: indicates if Replies to Comments will be notified"),
            marketing       : NSLocalizedString("Suggestions",
                                comment: "Setting: WordPress.com Suggestions"),
            research        : NSLocalizedString("Research",
                                comment: "Setting: WordPress.com Surveys"),
            community       : NSLocalizedString("Community",
                                comment: "Setting: WordPress.com Community")
        ]
        
        static let localizedDetailsMap = [
            marketing       : NSLocalizedString("Tips for getting the most out of WordPress.com.",
                                comment: "WordPress.com Marketing Footer Text"),
            research        : NSLocalizedString("Opportunities to participate in WordPress.com research & surveys.",
                                comment: "WordPress.com Research Footer Text"),
            community       : NSLocalizedString("Information on WordPress.com courses and events (online & in-person).",
                                comment: "WordPress.com Community Footer Text")
        ]
    }
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
