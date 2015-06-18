import Foundation


public class RemoteNotificationsSettings
{
    let sites               : [Site]
    let other               : [Other]
    let wpcom               : WordPressCom?
    
    init?(rawSettings : NSDictionary?) {
        sites               = Site.parseSites(rawSettings?.arrayForKey("sites") as? [NSDictionary])
        other               = Other.parseOther(rawSettings?.dictionaryForKey("other"))
        wpcom               = WordPressCom(rawWordPressCom: rawSettings?.dictionaryForKey("wpcom"))
        
        if rawSettings == nil {
            return nil
        }
    }
    

    // MARK: - Nested Enums
    public enum Kind : String {
        case Timeline       = "timeline"
        case Email          = "email"
        case Device         = "device"
        
        static let allValues = [ Timeline, Email, Device ]
    }
    
    
    // MARK: - Nested Class'ess
    public class Site
    {
        let siteId          : Int
        let kind            : Kind
        let newComment      : Bool
        let commentLike     : Bool
        let postLike        : Bool
        let follow          : Bool
        let achievement     : Bool
        let mentions        : Bool
        
        init?(siteId theSiteId: Int?, kind theKind: Kind, dict rawSite: NSDictionary?) {
            siteId          = theSiteId                                         ?? Int.max
            kind            = theKind
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
                
                for kind in Kind.allValues {
                    if let site = Site(siteId: siteId, kind: kind, dict: rawSite.dictionaryForKey(kind.rawValue)) {
                        parsed.append(site)
                    }
                }
            }
            
            return parsed
        }
    }
    
    public class Other
    {
        let kind            : Kind
        let commentLike     : Bool
        let commentReply    : Bool
        
        init?(kind theKind: Kind, rawOther : NSDictionary?) {
            kind            = theKind
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
            
            for kind in Kind.allValues {
                if let other = Other(kind: kind, rawOther: rawOther?.dictionaryForKey(kind.rawValue)) {
                    parsed.append(other)
                }
            }
            
            return parsed
        }
    }
    
    public class WordPressCom
    {
        let news            : Bool
        let recommendations : Bool
        let promotion       : Bool
        let digest          : Bool
        
        init?(rawWordPressCom : NSDictionary?) {
            news            = rawWordPressCom?.numberForKey("news")?.boolValue              ?? false
            recommendations = rawWordPressCom?.numberForKey("recommendation")?.boolValue    ?? false
            promotion       = rawWordPressCom?.numberForKey("promotion")?.boolValue         ?? false
            digest          = rawWordPressCom?.numberForKey("digest")?.boolValue            ?? false
            
            if rawWordPressCom == nil {
                return nil
            }
        }
    }
}
