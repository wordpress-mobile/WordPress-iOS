import Foundation


/**
*  @class           RemoteNotificationsSettings
*  @brief           The goal of this class is to parse Notification Settings data from the backend, and structure
*                   it into a flat hierarchy, for easy access / mapping.
*/

public class RemoteNotificationsSettings
{
    let sites               : [Site]
    let other               : [Other]
    let wpcom               : WordPressCom?
    
    init?(dictionary : NSDictionary?) {
        sites               = Site.parseSites(dictionary?.arrayForKey("sites") as? [NSDictionary])
        other               = Other.parseOther(dictionary?.dictionaryForKey("other"))
        wpcom               = WordPressCom(dictionary: dictionary?.dictionaryForKey("wpcom"))
        
        if dictionary == nil {
            return nil
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
        case Timeline       = "timeline"
        case Email          = "email"
        case Device         = "device"
        
        static let allValues = [ Timeline, Email, Device ]
    }
    
    
    /**
    *  @class       Site
    *  @brief       This nested class represents the Notification Settings, for a given Site, in a specific stream.
    */
    public class Site
    {
        let siteId          : Int
        let streamKind      : StreamKind
        let newComment      : Bool
        let commentLike     : Bool
        let postLike        : Bool
        let follow          : Bool
        let achievement     : Bool
        let mentions        : Bool
        
        init?(siteId theSiteId: Int?, streamKind theStreamKind: StreamKind, dict rawSite: NSDictionary?) {
            siteId          = theSiteId                                         ?? Int.max
            streamKind      = theStreamKind
            newComment      = rawSite?.numberForKey("new-comment")?.boolValue   ?? false
            commentLike     = rawSite?.numberForKey("comment-like")?.boolValue  ?? false
            postLike        = rawSite?.numberForKey("post-like")?.boolValue     ?? false
            follow          = rawSite?.numberForKey("follow")?.boolValue        ?? false
            achievement     = rawSite?.numberForKey("achievement")?.boolValue   ?? false
            mentions        = rawSite?.numberForKey("mentions")?.boolValue      ?? false
            
            if theSiteId == nil || rawSite == nil {
                return nil
            }
        }
        
        public static func parseSites(rawSites: [NSDictionary]?) -> [Site] {
            var parsed = [Site]()
            if rawSites == nil {
                return parsed
            }
            
            for rawSite in rawSites! {
                let siteId = rawSite.numberForKey("site_id") as? Int
                
                for streamKind in StreamKind.allValues {
                    if let site = Site(siteId: siteId, streamKind: streamKind, dict: rawSite.dictionaryForKey(streamKind.rawValue)) {
                        parsed.append(site)
                    }
                }
            }
            
            return parsed
        }
    }
    
    
    /**
    *  @class       Other
    *  @brief       This nested class represents the Notification Settings for "Other Sites" (AKA 3rd party blogs), 
    *               in a specific stream.
    */
    public class Other
    {
        let streamKind      : StreamKind
        let commentLike     : Bool
        let commentReply    : Bool
        
        init?(streamKind theStreamKind: StreamKind, rawOther : NSDictionary?) {
            streamKind      = theStreamKind
            commentLike     = rawOther?.numberForKey("comment-like")?.boolValue  ?? false
            commentReply    = rawOther?.numberForKey("comment-reply")?.boolValue ?? false
            
            if rawOther == nil {
                return nil
            }
        }
        
        public static func parseOther(rawOther: NSDictionary?) -> [Other] {
            var parsed = [Other]()
            if rawOther == nil {
                return parsed
            }
            
            for streamKind in StreamKind.allValues {
                if let other = Other(streamKind: streamKind, rawOther: rawOther?.dictionaryForKey(streamKind.rawValue)) {
                    parsed.append(other)
                }
            }
            
            return parsed
        }
    }
    
    
    /**
    *  @class       WordPressCom
    *  @brief       This nested class represents the Notification Settings for WordPress.com. This is not 
    *               associated to a specific site.
    */
    public class WordPressCom
    {
        let news            : Bool
        let recommendations : Bool
        let promotion       : Bool
        let digest          : Bool
        
        init?(dictionary : NSDictionary?) {
            news            = dictionary?.numberForKey("news")?.boolValue              ?? false
            recommendations = dictionary?.numberForKey("recommendation")?.boolValue    ?? false
            promotion       = dictionary?.numberForKey("promotion")?.boolValue         ?? false
            digest          = dictionary?.numberForKey("digest")?.boolValue            ?? false
            
            if dictionary == nil {
                return nil
            }
        }
    }
}
