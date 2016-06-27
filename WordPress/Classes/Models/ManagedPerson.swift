import Foundation
import CoreData

// MARK: - Reflects a Person, stored in Core Data
//
class ManagedPerson: NSManagedObject {

    func updateWith<T : Person>(person: T) {
        avatarURL = person.avatarURL?.absoluteString
        displayName = person.displayName
        firstName = person.firstName
        lastName = person.lastName
        role = String(person.role)
        siteID = Int64(person.siteID)
        userID = Int64(person.ID)
        linkedUserID = Int64(person.linkedUserID)
        username = person.username
        isSuperAdmin = person.isSuperAdmin
        kind = Int16(person.dynamicType.kind.rawValue)
    }

    func toUnmanaged() -> Person {
        switch Int(kind) {
        case PersonKind.User.rawValue:
            return User(managedPerson: self)
        default:
            return Follower(managedPerson: self)
        }
    }
}
