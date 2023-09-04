import Foundation
import CoreData

open class PublicizeService: NSManagedObject {
    @objc static let googlePlusServiceID = "google_plus"
    @objc static let facebookServiceID = "facebook"
    @objc static let defaultStatus = "ok"
    @objc static let unsupportedStatus = "unsupported"

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

extension PublicizeService {

    /// A convenient value-type representation for the destination sharing service.
    enum ServiceName: String {
        case facebook
        case twitter
        case tumblr
        case linkedin
        case instagram = "instagram-business"
        case mastodon
        case unknown

        /// Returns the local image for the icon representing the social network.
        var localIconImage: UIImage {
            WPStyleGuide.socialIcon(for: rawValue as NSString)
        }

        /// A string describing the service in a human-readable format.
        var description: String {
            rawValue.split(separator: "-").joined(separator: " ").localizedCapitalized
        }
    }

    var name: ServiceName {
        .init(rawValue: serviceID) ?? .unknown
    }
}
