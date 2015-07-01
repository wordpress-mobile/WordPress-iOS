import Foundation


/**
*  @class           NotificationSettings
*  @brief           The goal of this class is to encapsulate all of the User's Notification Settings in a generic way.
*                   Settings are grouped into different Channels, and each channel may contain different streams.
*/

public class NotificationSettings
{
    public let channel : Channel
    public let streams : [Stream]
    
    
    /**
    *  @enum        Channel
    *  @brief       Represents a communication channel that may post notifications to the user.
    */
    public enum Channel : Equatable {
        case Site(siteId: Int?)
        case Other
        case WordPressCom
        
        static let allValues = [ Site(siteId: nil), Other, WordPressCom ]
        
        
        /**
        *  @details Returns the localized description of the current enum value
        */
        func description() -> String {
            switch self {
            case .Site:
                return NSLocalizedString("WordPress Blog", comment: "Notification Settings Channel")
            case .Other:
                return NSLocalizedString("Comments on Other Sites", comment: "Notification Settings Channel")
            case .WordPressCom:
                return NSLocalizedString("Updates from WordPress.com", comment: "Notification Settings Channel")
            }
        }
        
        
        /**
        *  @details Helper method to convert RemoteNotificationSettings.Channel into a NotificationSettings.Channel enum.
        *  @param   remote      An instance of the RemoteNotificationSettings.Channel enum
        *  @returns             Instance of NotificationSettings.Channel Enum
        */
        private static func fromRemote(remote: RemoteNotificationSettings.Channel) -> Channel {
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
            
            
            /**
            *  @details Returns the localized description of the current enum value
            */
            func description() -> String {
                switch self {
                case .Timeline:
                    return NSLocalizedString("Timeline", comment: "WordPress.com Notifications Timeline")
                case .Email:
                    return NSLocalizedString("Email", comment: "Email Notifications Channel")
                case .Device:
                    return NSLocalizedString("Push Notifications", comment: "Mobile Push Notifications")
                }
            }
            
            static let allValues = [ Timeline, Email, Device ]
        }
        
        
        /**
        *  @details Private Designated Initializer
        *  @param   kind            The Kind of stream we're currently dealing with
        *  @param   preferences     Raw remote preferences, retrieved from the backend
        */
        private init(kind: Kind, preferences: [String : Bool]?) {
            self.kind           = kind
            self.preferences    = preferences
        }
        
        
        /**
        *  @details     Static Helper that will parse RemoteNotificationSettings.Stream instances into a collection of
        *               NotificationSettings.Stream instances.
        *  @param       remoteSettings  Array of RemoteNotificationSettings.Stream
        *  @returns                     An array of NotificationSettings.Stream objects
        */
        private static func fromArray(remoteStreams: [RemoteNotificationSettings.Stream]) -> [Stream] {
            var parsed = [Stream]()
            
            for remoteStream in remoteStreams {
                let kind    = Kind(rawValue: remoteStream.kind.rawValue)!
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
        self.channel = Channel.fromRemote(settings.channel)
        self.streams = Stream.fromArray(settings.streams)
    }

    
    /**
    *  @details     Static Helper that will parse RemoteNotificationSettings instances into a collection of 
    *               NotificationSettings instances.
    *  @param       remoteSettings  Array of RemoteNotificationSettings
    *  @returns                     An array of NotificationSettings objects
    */
    public static func fromArray(remoteSettings: [RemoteNotificationSettings]) -> [NotificationSettings] {
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
