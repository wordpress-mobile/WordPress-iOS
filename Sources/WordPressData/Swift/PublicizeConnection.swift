import Foundation
import CoreData

@objc(PublicizeConnection)
open class PublicizeConnection: NSManagedObject {
    // Relations
    @NSManaged open var blog: Blog

    // Properties
    @NSManaged open var connectionID: NSNumber
    @NSManaged open var externalID: String
    @NSManaged open var externalName: String
    @NSManaged open var externalDisplay: String
    @NSManaged open var externalProfilePicture: String
    @NSManaged open var externalProfileURL: String
    @NSManaged open var keyringConnectionID: NSNumber
    @NSManaged open var keyringConnectionUserID: NSNumber
    @NSManaged open var label: String
    @NSManaged open var refreshURL: String
    @NSManaged open var service: String
    @NSManaged open var shared: Bool
    @NSManaged open var status: String

    // TODO: Remove dateIssued, dateExpires, externalFollowerCount, siteID, userID
    // from the Core Data model (WordPress.xcdatamodeld) in a new model version.

    @objc open func isBroken() -> Bool {
        return status != "ok"
    }

    @objc open func mustDisconnect() -> Bool {
        return status == "must-disconnect"
    }

    @objc open func requiresUserAction() -> Bool {
        return isBroken() || mustDisconnect()
    }

    @objc open func mustDisconnectFacebook() -> Bool {
        return mustDisconnect() && service == PublicizeService.facebookServiceID
    }
}
