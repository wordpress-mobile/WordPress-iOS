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
    *  @details     Designated Initializer
    *  @param       channel     The related Notifications Channel
    *  @param       streams     An array of all of the involved streams
    */
    public init(channel: Channel, streams: [Stream]) {
        self.channel = channel
        self.streams = streams
    }
    
    
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
                    return NSLocalizedString("Timeline", comment: "WordPress.com Notifications Timeline")
                case .Email:
                    return NSLocalizedString("Email", comment: "Email Notifications Channel")
                case .Device:
                    return NSLocalizedString("Push Notifications", comment: "Mobile Push Notifications")
                }
            }
            
            static let allValues = [ Timeline, Email, Device ]
        }
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
