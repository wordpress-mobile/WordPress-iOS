import Foundation


/**
*  @class           RemoteNotificationsSettings
*  @brief           The goal of this class is to parse Notification Settings data from the backend, and structure
*                   it into a flat hierarchy, for easy access / mapping.
*/

public class RemoteNotificationsSettings
{
    let sites : [Site]
    let other : [Other]
    let wpcom : WordPressCom
    
    init(dictionary : NSDictionary?) {
        sites = Site.parseSites(dictionary?.arrayForKey("sites") as? [NSDictionary])
        other = Other.parseOther(dictionary?.dictionaryForKey("other"))
        wpcom = WordPressCom(settings: dictionary?.dictionaryForKey("wpcom") as? [String: Bool])
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
        case Device     = "devices"
        
        static let allValues = [ Timeline, Email, Device ]
    }
    
    
    /**
    *  @class       Site
    *  @brief       This nested class represents the Notification Settings, for a given Site, in a specific stream.
    */
    public class Site
    {
        let siteId      : Int
        let streamKind  : StreamKind
        let newComment  : Bool
        let commentLike : Bool
        let postLike    : Bool
        let follow      : Bool
        let achievement : Bool
        let mentions    : Bool
        
        init(siteId _siteId: Int, streamKind _streamKind: StreamKind, settings _settings: NSDictionary) {
            siteId      = _siteId
            streamKind  = _streamKind
            newComment  = _settings.numberForKey("new-comment")?.boolValue  ?? false
            commentLike = _settings.numberForKey("comment-like")?.boolValue ?? false
            postLike    = _settings.numberForKey("post-like")?.boolValue    ?? false
            follow      = _settings.numberForKey("follow")?.boolValue       ?? false
            achievement = _settings.numberForKey("achievement")?.boolValue  ?? false
            mentions    = _settings.numberForKey("mentions")?.boolValue     ?? false
        }
        
        
        /**
        *  @brief   Parses "Site" settings dictionary, into a flat collection of "Site" object instances.
        *
        *  @param   otherSettings   The raw dictionary retrieved from the backend.
        *  @returns                 An array of Site objects. Each Site will get three instances, one per strem
        *                           settings (we flatten out the collection).
        */
        private static func parseSites(allSiteSettings: [NSDictionary]?) -> [Site] {
            var parsed = [Site]()
            if allSiteSettings == nil {
                return parsed
            }
            
            for siteSettings in allSiteSettings! {
                let siteId = siteSettings.numberForKey("site_id") as? Int
                if siteId == nil {
                    continue
                }
                
                // Timeline + Email: A single dictionary
                for streamKind in [StreamKind.Timeline, .Email] {
                    if let streamSettings = siteSettings.dictionaryForKey(streamKind.rawValue) {
                        parsed.append(Site(siteId: siteId!, streamKind: streamKind, settings: streamSettings))
                    }
                }
                
                // Device: An array of dictionaries
                if let deviceSettings = siteSettings.arrayForKey(StreamKind.Device.rawValue)?.first as? NSDictionary {
                    parsed.append(Site(siteId: siteId!, streamKind: StreamKind.Device, settings: deviceSettings))
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
        
        init(streamKind _streamKind: StreamKind, settings _settings: NSDictionary) {
            streamKind      = _streamKind
            commentLike     = _settings.numberForKey("comment-like")?.boolValue   ?? false
            commentReply    = _settings.numberForKey("comment-reply")?.boolValue  ?? false
        }
        
        /**
        *  @brief   Parses "Other Sites" settings dictionary, into a flat collection of "Other" object instances.
        *
        *  @param   otherSettings   The raw dictionary retrieved from the backend.
        *  @returns                 An array of `Other` object instances, one per stream
        */
        private static func parseOther(otherSettings: NSDictionary?) -> [Other] {
            var parsed = [Other]()

            // Timeline + Email: A single dictionary
            for streamKind in [StreamKind.Timeline, .Email] {
                if let streamSettings = otherSettings?.dictionaryForKey(streamKind.rawValue) {
                    parsed.append(Other(streamKind: streamKind, settings: streamSettings))
                }
            }
            
            // Device: An array of dictionaries
            if let deviceSettings = otherSettings?.arrayForKey(StreamKind.Device.rawValue)?.first as? NSDictionary {
                parsed.append(Other(streamKind: .Device, settings: deviceSettings))
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
        
        init(settings _settings: [String: Bool]?) {
            news            = _settings?["news"]             ?? false
            recommendations = _settings?["recommendation"]   ?? false
            promotion       = _settings?["promotion"]        ?? false
            digest          = _settings?["digest"]           ?? false
        }
    }
}
