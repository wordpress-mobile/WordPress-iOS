import Foundation


/**
*  @class           NotificationSettings
*  @brief           The goal of this class is to encapsulate all of the User's Notification Settings, in a generic way.
*                   The user may toggle settings for a specific Site, 3rd party sites, or WordPress.com.
*                   Each set of settings may be applicable to different streams (Email / Timeline / Push Notifications).
*/

public class NotificationSettings
{
    public let channel : Channel
    public let streams : [Stream]!
    
    
    /**
    *  @enum        Channel
    *  @brief       Represents a communication channel that may post notifications to the user.
    */
    public enum Channel : Equatable {
        case Site(siteId: Int)
        case Other
        case WordPressCom
        
        static func fromRemoteChannel(remote: RemoteNotificationSettings.Channel) -> Channel {
            switch remote {
            case let .Site(siteId):
                return .Site(siteId: siteId)
            case .Other:
                return .Other
            case .WordPressCom:
                return .WordPressCom
            }
        }
    }
    
    
    /**
    *  @class       Stream
    *  @brief       Contains the Notification Settings for a specific communications stream.
    */
    public class Stream {
        public var kind         : Kind?
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
        private init(kind: Kind?, preferences: [String : Bool]?) {
            self.kind           = kind
            self.preferences    = preferences
        }
        
        private static func fromRemoteArray(streams: [RemoteNotificationSettings.Stream]) -> [Stream] {
            var parsed = [Stream]()
            
            for remoteStream in streams {
                let kind    = Kind(rawValue: remoteStream.kind?.rawValue ?? String())
                let stream  = Stream(kind: kind, preferences: remoteStream.preferences)
                
                parsed.append(stream)
            }
            
            return parsed
        }
    }
    
    
    /**
    *  @details     Private Designated Initializer
    *  @param       settings   An instance of RemoteNotificationSettings
    */
    private init(settings: RemoteNotificationSettings) {
        self.channel = Channel.fromRemoteChannel(settings.channel)
        self.streams = Stream.fromRemoteArray(settings.streams)
    }

    
    public static func fromRemoteArray(remoteSettings: [RemoteNotificationSettings]) -> [NotificationSettings] {
        var parsed = [NotificationSettings]()

        for remoteSetting in remoteSettings {
            parsed.append(NotificationSettings(settings: remoteSetting))
        }
        
        return parsed
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
    case (let .Site(firstSiteId), let .Site(secondSiteId)) where firstSiteId == secondSiteId:
        return true
    case (.Other, .Other):
        return true
    case (.WordPressCom, .WordPressCom):
        return true
    default:
        return false
    }
}



//  TODO:
//      -   Defaults
//      -   Descriptions
//      -   NotificationSettings Docs
//
//    public class Site
//    {
//        newComment  = settings["new-comment"]  as? Bool ?? false
//        commentLike = settings["comment-like"] as? Bool ?? false
//        postLike    = settings["post-like"]    as? Bool ?? false
//        follow      = settings["follow"]       as? Bool ?? false
//        achievement = settings["achievement"]  as? Bool ?? false
//        mentions    = settings["mentions"]     as? Bool ?? false
//    }
//
//    public class Other
//    {
//        commentLike     = settings["comment-like"]  as? Bool ?? false
//        commentReply    = settings["comment-reply"] as? Bool ?? false
//    }
//
//    public class WordPressCom
//    {
//        news            = settings?["news"]            as? Bool ?? false
//        recommendations = settings?["recommendation"]  as? Bool ?? false
//        promotion       = settings?["promotion"]       as? Bool ?? false
//        digest          = settings?["digest"]          as? Bool ?? false
//    }


