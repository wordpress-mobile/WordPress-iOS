import Foundation


/**
*  @class           RemoteNotificationSettings
*  @brief           The goal of this class is to parse Notification Settings data from the backend, and structure
*                   it into a flat hierarchy, for easy access / mapping.
*/

public class RemoteNotificationSettings
{
    let sites           : [Site]
    let other           : [Other]
    let wpcom           : WordPressCom
    
    init(dictionary : NSDictionary?) {
        sites           = Site.fromArray(dictionary?["sites"] as? [NSDictionary])
        other           = Other.fromDictionary(dictionary?["other"] as? NSDictionary)
        wpcom           = WordPressCom.fromDictionary(dictionary?["wpcom"] as? NSDictionary)
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
            newComment  = _settings["new-comment"]  as? Bool ?? false
            commentLike = _settings["comment-like"] as? Bool ?? false
            postLike    = _settings["post-like"]    as? Bool ?? false
            follow      = _settings["follow"]       as? Bool ?? false
            achievement = _settings["achievement"]  as? Bool ?? false
            mentions    = _settings["mentions"]     as? Bool ?? false
        }
        
        
        /**
        *  @brief   Parses a collection of "Site" dictionaries, into a flat collection of "Site" object instances.
        *
        *  @param   sitesArray      The raw array of dictionaries, retrieved from the backend.
        *  @returns                 An array of Site objects. Each Site will get three instances, one per strem
        *                           settings (we flatten out the collection).
        */
        private static func fromArray(sitesArray: [NSDictionary]?) -> [Site] {
            var parsed = [Site]()
            
            if let unwrappedSitesSettings = sitesArray {
                for siteSettings in unwrappedSitesSettings {
                    parsed += fromDictionary(siteSettings)
                }
            }
            
            return parsed
        }
        
        /**
        *  @brief   Parses "Site" settings dictionary, into a flat collection of "Site" object instances.
        *
        *  @param   siteDictionary  The raw "Site Settings" dictionary retrieved from the backend.
        *  @returns                 An array of Site objects. Each Site will get three instances, one per stream.
        */
        public static func fromDictionary(siteDictionary: NSDictionary?) -> [Site] {
            var parsed = [Site]()
            
            if let siteId = siteDictionary?["site_id"] as? Int {
                for streamKind in StreamKind.allValues {
                    if let streamSettings = siteDictionary?[streamKind.rawValue] as? NSDictionary {
                        parsed.append(Site(siteId: siteId, streamKind: streamKind, settings: streamSettings))
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
        
        init(streamKind _streamKind: StreamKind, settings _settings: NSDictionary) {
            streamKind      = _streamKind
            commentLike     = _settings["comment-like"]  as? Bool ?? false
            commentReply    = _settings["comment-reply"] as? Bool ?? false
        }
        
        /**
        *  @brief   Parses "Other Sites" settings dictionary into a flat collection of "Other" object instances,
        *           one per stream.
        *
        *  @param   otherDictionary The raw "Other Settings" dictionary, retrieved from the backend.
        *  @returns                 An array of "Other" object instances, one per stream.
        */
        public static func fromDictionary(otherDictionary: NSDictionary?) -> [Other] {
            var parsed = [Other]()

            for streamKind in StreamKind.allValues {
                if let streamSettings = otherDictionary?[streamKind.rawValue] as? NSDictionary {
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
        let news            : Bool
        let recommendations : Bool
        let promotion       : Bool
        let digest          : Bool
        
        init(settings _settings: NSDictionary?) {
            news            = _settings?["news"]            as? Bool ?? false
            recommendations = _settings?["recommendation"]  as? Bool ?? false
            promotion       = _settings?["promotion"]       as? Bool ?? false
            digest          = _settings?["digest"]          as? Bool ?? false
        }
        
        
        /**
        *  @brief   Parses "WordPress.com" settings dictionary, and returns a WordPressCom instance.
        *
        *  @param   wordPressComDictionary  The raw "WordPress.com" dictionary, retrieved from the backend.
        *  @returns                         An instance of WordPress.com with the parsed settings.
        */
        public static func fromDictionary(wordPressComDictionary: NSDictionary?) -> WordPressCom {
            return WordPressCom(settings: wordPressComDictionary)
        }
    }
}
