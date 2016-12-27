import Foundation
import CoreData

// MARK: - Reflects a Person, stored in Core Data
//
class ManagedPerson: NSManagedObject {

    func updateWith<T: Person>(_ person: T) {
        avatarURL = person.avatarURL?.absoluteString
        displayName = person.displayName
        firstName = person.firstName
        lastName = person.lastName
        role = String(describing: person.role)
        siteID = Int64(person.siteID)
        userID = Int64(person.ID)
        linkedUserID = Int64(person.linkedUserID)
        username = person.username
        isSuperAdmin = person.isSuperAdmin
        kind = Int16(type(of: person).kind.rawValue)
    }

    func toUnmanaged() -> Person {
        switch Int(kind) {
        case PersonKind.user.rawValue:
            return User(managedPerson: self)
        case PersonKind.viewer.rawValue:
            return Viewer(managedPerson: self)
        default:
            return Follower(managedPerson: self)
        }
    }
}
