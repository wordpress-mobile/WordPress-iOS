import Foundation
import CoreData

// MARK: - Encapsulates all of the ManagedPerson Core Data properties.
//
extension ManagedPerson {
    @NSManaged var avatarURL: String?
    @NSManaged var displayName: String
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var role: String
    @NSManaged var siteID: Int32
    @NSManaged var userID: Int32
    @NSManaged var linkedUserID: Int32
    @NSManaged var username: String
    @NSManaged var isSuperAdmin: Bool
    @NSManaged var blog: Blog
}
