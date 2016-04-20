import Foundation
import CoreData

public class PublicizeConnection : NSManagedObject
{
    // Relations
    @NSManaged public var blog: Blog

    // Properties
    @NSManaged public var connectionID: NSNumber
    @NSManaged public var dateIssued: NSDate
    @NSManaged public var dateExpires: NSDate?
    @NSManaged public var externalID: String
    @NSManaged public var externalName: String
    @NSManaged public var externalDisplay: String
    @NSManaged public var externalProfilePicture: String
    @NSManaged public var externalProfileURL: String
    @NSManaged public var externalFollowerCount: NSNumber
    @NSManaged public var keyringConnectionID: NSNumber
    @NSManaged public var keyringConnectionUserID: NSNumber
    @NSManaged public var label: String
    @NSManaged public var refreshURL: String
    @NSManaged public var service: String
    @NSManaged public var shared: Bool
    @NSManaged public var status: String
    @NSManaged public var siteID: NSNumber
    @NSManaged public var userID: NSNumber

    public func isBroken() -> Bool {
        return status == "broken"
    }
}
