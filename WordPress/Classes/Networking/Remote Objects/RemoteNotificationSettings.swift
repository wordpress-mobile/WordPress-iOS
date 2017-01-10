import Foundation


/// The goal of this class is to parse Notification Settings data from the backend, and structure it in a
/// meaningful way. Notification Settings come in three different flavors:
///
///     - "Our Own" Blog Settings
///     - "Third Party" Site Settings
///     - WordPress.com Settings
///
/// Each one of the possible channels may post notifications via different streams:
/// Email, Push Notifications, and Timeline.
///
open class RemoteNotificationSettings {
    /// Represents the Channel to which the current settings are associated.
    ///
    open let channel: Channel

    /// Contains an array of the available Notification Streams.
    ///
    open let streams: [Stream]



    /// Represents a communication channel that may post notifications to the user.
    ///
    public enum Channel: Equatable {
        case blog(blogId: Int)
        case other
        case wordPressCom
    }


    /// Contains the Notification Settings for a specific communications stream.
    ///
    open class Stream {
        open var kind: Kind
        open var preferences: [String : Bool]?


        /// Enumerates all of the possible Stream Kinds
        ///
        public enum Kind: String {
            case Timeline       = "timeline"
            case Email          = "email"
            case Device         = "device"

            static let allValues = [ Timeline, Email, Device ]
        }


        /// Private Designated Initializer
        ///
        /// - Parameters:
        ///     - kind: The Kind of stream we're currently dealing with
        ///     - preferences: Raw remote preferences, retrieved from the backend
        ///
        fileprivate init(kind: Kind, preferences: NSDictionary?) {
            self.kind           = kind
            self.preferences    = filterNonBooleanEntries(preferences)
        }


        /// Helper method that will filter out non boolean entries, and return a native Swift collection.
        ///
        /// - Parameter dictionary: NextStep Dictionary containing raw values
        ///
        /// - Returns: A native Swift dictionary, containing only the Boolean entries
        ///
        fileprivate func filterNonBooleanEntries(_ dictionary: NSDictionary?) -> [String : Bool] {
            var filtered = [String: Bool]()
            if dictionary == nil {
                return filtered
            }

            for (key, value) in dictionary! {
                if let stringKey = key   as? String,
                   let boolValue = value as? Bool {
                    let value = value as AnyObject
                    // NSNumbers might get converted to Bool anyways
                    if value === kCFBooleanFalse || value === kCFBooleanTrue {
                        filtered[stringKey] = boolValue
                    }
                }
            }

            return filtered
        }


        /// Parser method that will convert a raw dictionary of stream settings into Swift Native objects.
        ///
        /// - Parameter dictionary: NextStep Dictionary containing raw Stream Preferences
        ///
        /// - Returns: A native Swift array containing Stream entities
        ///
        fileprivate static func fromDictionary(_ dictionary: NSDictionary?) -> [Stream] {
            var parsed = [Stream]()

            for kind in Kind.allValues {
                if let preferences = dictionary?[kind.rawValue] as? NSDictionary {
                    parsed.append(Stream(kind: kind, preferences: preferences))
                }
            }

            return parsed
        }
    }


    /// Private Designated Initializer
    ///
    /// - Parameters:
    ///     - channel: The communications channel that uses the current settings
    ///     - settings: Raw dictionary containing the remote settings response
    ///
    fileprivate init(channel: Channel, settings: NSDictionary?) {
        self.channel = channel
        self.streams = Stream.fromDictionary(settings)
    }


    /// Private Designated Initializer
    ///
    /// - Parameter wpcomSettings: Dictionary containing the collection of WordPress.com Settings
    ///
    fileprivate init(wpcomSettings: NSDictionary?) {
        // WordPress.com is a special scenario: It contains just one (unspecified) stream: Email
        self.channel = Channel.wordPressCom
        self.streams = [ Stream(kind: .Email, preferences: wpcomSettings) ]
    }


    /// Private Convenience Initializer
    ///
    /// - Parameter blogSettings: Dictionary containing the collection of settings for a single blog
    ///
    fileprivate convenience init(blogSettings: NSDictionary?) {
        let blogId = blogSettings?["blog_id"] as? Int ?? Int.max
        self.init(channel: Channel.blog(blogId: blogId), settings: blogSettings)
    }


    /// Private Convenience Initializer
    ///
    /// - Parameter otherSettings: Dictionary containing the collection of "Other Settings"
    ///
    fileprivate convenience init(otherSettings: NSDictionary?) {
        self.init(channel: Channel.other, settings: otherSettings)
    }



    /// Static Helper that will parse all of the Remote Settings, into a collection of Swift Native
    /// RemoteNotificationSettings objects.
    ///
    /// - Parameter dictionary: Dictionary containing the remote Settings response
    ///
    /// - Returns: An array of RemoteNotificationSettings objects
    ///
    open static func fromDictionary(_ dictionary: NSDictionary?) -> [RemoteNotificationSettings] {
        var parsed = [RemoteNotificationSettings]()

        if let rawBlogs = dictionary?["blogs"] as? [NSDictionary] {
            for rawBlog in rawBlogs {
                let parsedBlog = RemoteNotificationSettings(blogSettings: rawBlog)
                parsed.append(parsedBlog)
            }
        }

        let other = RemoteNotificationSettings(otherSettings: dictionary?["other"] as? NSDictionary)
        parsed.append(other)

        let wpcom = RemoteNotificationSettings(wpcomSettings: dictionary?["wpcom"] as? NSDictionary)
        parsed.append(wpcom)

        return parsed
    }
}



/// Swift requires this method to be implemented globally. Sorry about that!
///
/// - Parameters:
///     - lhs: Left Hand Side Channel
///     - rhs: Right Hand Side Channel
///
/// - Returns: A boolean indicating whether two channels are equal. Or not!
///
public func ==(lhs: RemoteNotificationSettings.Channel, rhs: RemoteNotificationSettings.Channel) -> Bool {
    switch (lhs, rhs) {
    case (let .blog(firstBlogId), let .blog(secondBlogId)) where firstBlogId == secondBlogId:
        return true
    case (.other, .other):
        return true
    case (.wordPressCom, .wordPressCom):
        return true
    default:
        return false
    }
}
