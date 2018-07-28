import Foundation
import CoreData

open class PublicizeConnection: NSManagedObject {
    // Relations
    @NSManaged open var blog: Blog

    // Properties
    @NSManaged open var connectionID: NSNumber
    @NSManaged open var dateIssued: Date
    @NSManaged open var dateExpires: Date?
    @NSManaged open var externalID: String
    @NSManaged open var externalName: String
    @NSManaged open var externalDisplay: String
    @NSManaged open var externalProfilePicture: String
    @NSManaged open var externalProfileURL: String
    @NSManaged open var externalFollowerCount: NSNumber
    @NSManaged open var keyringConnectionID: NSNumber
    @NSManaged open var keyringConnectionUserID: NSNumber
    @NSManaged open var label: String
    @NSManaged open var refreshURL: String
    @NSManaged open var service: String
    @NSManaged open var shared: Bool
    @NSManaged open var status: String
    @NSManaged open var siteID: NSNumber
    @NSManaged open var userID: NSNumber

    @objc open func isBroken() -> Bool {
        return status == "broken"
    }

    @objc open func mustDisconnect() -> Bool {
        return status == "must-disconnect"
    }
}
