import Foundation
import CoreData

// MARK: - Reflects a Person, stored in Core Data
//
class ManagedPerson: NSManagedObject {

    func updateWith(person: Person) {
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
        isFollower = person.dynamicType.isFollower
    }

    func toUnmanaged() -> Person {
        if isFollower {
            return Follower(managedPerson: self)
        }

        return User(managedPerson: self)
    }
}
