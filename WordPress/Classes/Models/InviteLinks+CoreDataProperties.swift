import Foundation
import CoreData


extension InviteLinks {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<InviteLinks> {
        return NSFetchRequest<InviteLinks>(entityName: "InviteLinks")
    }

    @NSManaged public var inviteKey: String!
    @NSManaged public var role: String!
    @NSManaged public var isPending: Bool
    @NSManaged public var inviteDate: Date!
    @NSManaged public var groupInvite: Bool
    @NSManaged public var expiry: Int64
    @NSManaged public var link: String!
    @NSManaged public var blog: Blog!

}
