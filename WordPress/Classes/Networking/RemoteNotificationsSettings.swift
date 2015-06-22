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
    
    init(dictionary : NSDictionary?) {
        
        let siteSettings    = dictionary?.arrayForKey("sites")      as? [NSDictionary]
        let otherSettings   = dictionary?.dictionaryForKey("other")
        let wpcomSettings   = dictionary?.dictionaryForKey("wpcom") as? [String: Bool]
        
        sites               = Site.parseSites(siteSettings)
        other               = Other.parseOther(otherSettings)
        wpcom               = WordPressCom(settings: wpcomSettings)
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
        case Timeline           = "timeline"
        case Email              = "email"
        case Device             = "device"
        
        static let allValues    = [ Timeline, Email, Device ]
    }
    
    
    /**
    *  @class       Site
    *  @brief       This nested class represents the Notification Settings, for a given Site, in a specific stream.
    */
    public class Site
    {
        let siteId          : Int
        let streamKind      : StreamKind
        let newComment      : Bool!
        let commentLike     : Bool!
        let postLike        : Bool!
        let follow          : Bool!
        let achievement     : Bool!
        let mentions        : Bool!
        
        init(siteId _siteId: Int, streamKind _streamKind: StreamKind, settings _settings: [String : Bool]) {
            siteId          = _siteId
            streamKind      = _streamKind
            newComment      = _settings["new-comment"]
            commentLike     = _settings["comment-like"]
            postLike        = _settings["post-like"]
            follow          = _settings["follow"]
            achievement     = _settings["achievement"]
            mentions        = _settings["mentions"]
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
                
                for streamKind in StreamKind.allValues {
                    if let streamSettings = siteSettings.dictionaryForKey(streamKind.rawValue) as? [String : Bool] {
                        parsed.append(Site(siteId: siteId!, streamKind: streamKind, settings: streamSettings))
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
        let commentLike     : Bool!
        let commentReply    : Bool!
        
        init(streamKind stream: StreamKind, settings: [String : Bool]) {
            streamKind      = stream
            commentLike     = settings["comment-like"]
            commentReply    = settings["comment-reply"]
        }
        
        /**
        *  @brief   Parses "Other Sites" settings dictionary, into a flat collection of "Other" object instances.
        *
        *  @param   otherSettings   The raw dictionary retrieved from the backend.
        *  @returns                 An array of `Other` object instances, one per stream
        */
        private static func parseOther(otherSettings: NSDictionary?) -> [Other] {
            var parsed = [Other]()

            for streamKind in StreamKind.allValues {
                if let streamSettings = otherSettings?.dictionaryForKey(streamKind.rawValue) as? [String : Bool] {
                    parsed.append(Other(streamKind: streamKind, settings: streamSettings))
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
        let news            : Bool!
        let recommendations : Bool!
        let promotion       : Bool!
        let digest          : Bool!
        
        init?(settings : [String: Bool]?) {
            news            = settings?["news"]
            recommendations = settings?["recommendation"]
            promotion       = settings?["promotion"]
            digest          = settings?["digest"]
            
            if settings == nil {
                return nil
            }
        }
    }
}
