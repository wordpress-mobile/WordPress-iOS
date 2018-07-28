import Foundation
import CoreData

open class PublicizeService: NSManagedObject {
    @objc static let googlePlusServiceID = "google_plus"
    @objc static let facebookServiceID = "facebook"

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
}
