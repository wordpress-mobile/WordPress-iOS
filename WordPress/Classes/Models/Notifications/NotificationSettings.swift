import Foundation


/**
*  @class           NotificationSettings
*  @brief           The goal of this class is to encapsulate all of the User's Notification Settings.
*/

public class NotificationSettings
{
    let sites           : [Site]
    let other           : [Other]
    let wpcom           : [WordPressCom]
    
    init(remote : RemoteNotificationSettings) {
        sites           = Site.fromArray(remote.sites)
        other           = Other.fromArray(remote.other)
        wpcom           = WordPressCom.fromArray(remote.wpcom)
    }
    
    
    /**
    *  @brief       Filters the settings for a specific site
    *
    *  @param       siteId  The siteId to filter.
    *  @returns             An array of NotificationSettings.Site objects.
    */
    public func settingsForSiteWithId(siteId: Int?) -> [NotificationSettings.Site] {
        if siteId == nil {
            return []
        }
        
        return sites.filter {
            (site: NotificationSettings.Site) in
            return site.siteId == siteId!
        }
    }

    
    
    /**
    *  @enum        StreamKind
    *  @brief       Each WordPress.com site may contain a different set of notification preferences, depending on
    *               the Stream Kind:
    *               -   WordPress.com Timeline
    *               -   Emails
    *               -   Push Notifications
    *
    */
    public enum StreamKind : String {
        case Timeline   = "timeline"
        case Email      = "email"
        case Device     = "device"
        
        static let allValues = [ Timeline, Email, Device ]
    }
    
    
    /**
    *  @class       Site
    *  @brief       This nested class represents the Notification Settings, for a given Site, in a specific stream.
    */
    public class Site
    {
        var siteId          : Int
        var streamKind      : StreamKind
        var newComment      : Bool
        var commentLike     : Bool
        var postLike        : Bool
        var follow          : Bool
        var achievement     : Bool
        var mentions        : Bool
        
        init(remote: RemoteNotificationSettings.Site) {
            siteId          = remote.siteId
            streamKind      = StreamKind(rawValue: remote.streamKind.rawValue)!
            newComment      = remote.newComment
            commentLike     = remote.commentLike
            postLike        = remote.postLike
            follow          = remote.follow
            achievement     = remote.achievement
            mentions        = remote.mentions
        }
        
        
        /**
        *  @brief   Parses a collection of "Remote Site" entities, into a collection of "Site" instances.
        *
        *  @param   remote          An array of RemoteNotificationSettings.Site entities.
        *  @returns                 An array of NotificationSettings.Site objects.
        */
        public static func fromArray(remote: [RemoteNotificationSettings.Site]) -> [Site] {
            return remote.map {
                return Site(remote: $0)
            }
        }
    }
    
    
    /**
    *  @class       Other
    *  @brief       This nested class represents the Notification Settings for "Other Sites" (AKA 3rd party blogs),
    *               in a specific stream.
    */
    public class Other
    {
        var streamKind      : StreamKind
        var commentLike     : Bool
        var commentReply    : Bool
        
        init(remote: RemoteNotificationSettings.Other) {
            streamKind      = StreamKind(rawValue: remote.streamKind.rawValue)!
            commentLike     = remote.commentLike
            commentReply    = remote.commentReply
        }
        
        
        /**
        *  @brief   Parses a collection of "Remote Other" entities, into a collection of "Other" instances.
        *
        *  @param   remote          An array of RemoteNotificationSettings.Other entities.
        *  @returns                 An array of NotificationSettings.Other objects.
        */
        public static func fromArray(remote: [RemoteNotificationSettings.Other]) -> [Other] {
            return remote.map {
                return Other(remote: $0)
            }
        }
    }
    
    
    /**
    *  @class       WordPressCom
    *  @brief       This nested class represents the Notification Settings for WordPress.com. This is not
    *               associated to a specific site.
    */
    public class WordPressCom
    {
        var news            : Bool
        var recommendations : Bool
        var promotion       : Bool
        var digest          : Bool
        
        init(remote: RemoteNotificationSettings.WordPressCom) {
            news            = remote.news
            recommendations = remote.recommendations
            promotion       = remote.promotion
            digest          = remote.digest
        }
        
        
        /**
        *  @brief   Parses a collection of "Remote WordPressCom" entities, into a collection of "WordPressCom" instances.
        *
        *  @param   remote          An array of RemoteNotificationSettings.WordPressCom entities.
        *  @returns                 An array of NotificationSettings.WordPressCom objects.
        */
        public static func fromArray(remote: [RemoteNotificationSettings.WordPressCom]) -> [WordPressCom] {
            return remote.map {
                return WordPressCom(remote: $0)
            }
        }
    }
}
