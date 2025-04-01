import Foundation
import CoreData
import WordPressShared

open class PublicizeService: NSManagedObject {
    @objc public static let googlePlusServiceID = "google_plus"
    @objc public static let facebookServiceID = "facebook"
    @objc public static let defaultStatus = "ok"
    @objc public static let unsupportedStatus = "unsupported"

    @NSManaged open var connectURL: String
    @NSManaged open var detail: String
    @NSManaged open var externalUsersOnly: Bool
    @NSManaged open var icon: String
    @NSManaged open var jetpackSupport: Bool
    @NSManaged open var jetpackModuleRequired: String
    @NSManaged open var label: String
    @NSManaged open var multipleExternalUserIDSupport: Bool
    @NSManaged open var order: NSNumber
    @NSManaged open var serviceID: String
    @NSManaged open var type: String
    @NSManaged open var status: String

    @objc open var isSupported: Bool {
        status == Self.defaultStatus
    }
}

// MARK: - Convenience Methods

public extension PublicizeService {

    /// A convenient value-type representation for the destination sharing service.
    enum ServiceName: String {
        case facebook
        case twitter
        case tumblr
        case linkedin
        case instagram = "instagram-business"
        case mastodon
        case threads
        case unknown

        /// A string describing the service in a human-readable format.
        public var description: String {
            rawValue.split(separator: "-").joined(separator: " ").localizedCapitalized
        }
    }

    var name: ServiceName {
        .init(rawValue: serviceID) ?? .unknown
    }
}
