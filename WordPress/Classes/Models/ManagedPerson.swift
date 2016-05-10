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
        siteID = Int32(person.siteID)
        userID = Int32(person.ID)
        linkedUserID = Int32(person.linkedUserID)
        username = person.username
        isSuperAdmin = person.isSuperAdmin
    }
}
