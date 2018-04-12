import Foundation
import CoreData
import WordPressKit

public typealias Person = RemotePerson

// MARK: - Reflects a Person, stored in Core Data
//
class ManagedPerson: NSManagedObject {

    func updateWith<T: Person>(_ person: T) {
        let canonicalAvatarURL = person.avatarURL.flatMap { Gravatar($0)?.canonicalURL }

        avatarURL = canonicalAvatarURL?.absoluteString
        displayName = person.displayName
        firstName = person.firstName
        lastName = person.lastName
        role = person.role
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

// MARK: - Extensions
//
extension Person {
    init(managedPerson: ManagedPerson) {
        self.init(ID: Int(managedPerson.userID),
                  username: managedPerson.username,
                  firstName: managedPerson.firstName,
                  lastName: managedPerson.lastName,
                  displayName: managedPerson.displayName,
                  role: managedPerson.role,
                  siteID: Int(managedPerson.siteID),
                  linkedUserID: Int(managedPerson.linkedUserID),
                  avatarURL: managedPerson.avatarURL.flatMap { URL(string: $0) },
                  isSuperAdmin: managedPerson.isSuperAdmin)
    }
}

extension User {
    init(managedPerson: ManagedPerson) {
        self.init(ID: Int(managedPerson.userID),
                  username: managedPerson.username,
                  firstName: managedPerson.firstName,
                  lastName: managedPerson.lastName,
                  displayName: managedPerson.displayName,
                  role: managedPerson.role,
                  siteID: Int(managedPerson.siteID),
                  linkedUserID: Int(managedPerson.linkedUserID),
                  avatarURL: managedPerson.avatarURL.flatMap { URL(string: $0) },
                  isSuperAdmin: managedPerson.isSuperAdmin)
    }
}

extension Follower {
    init(managedPerson: ManagedPerson) {
        self.init(ID: Int(managedPerson.userID),
                  username: managedPerson.username,
                  firstName: managedPerson.firstName,
                  lastName: managedPerson.lastName,
                  displayName: managedPerson.displayName,
                  role: RemoteRole.follower.slug,
                  siteID: Int(managedPerson.siteID),
                  linkedUserID: Int(managedPerson.linkedUserID),
                  avatarURL: managedPerson.avatarURL.flatMap { URL(string: $0) },
                  isSuperAdmin: managedPerson.isSuperAdmin)
    }
}

extension Viewer {
    init(managedPerson: ManagedPerson) {
        self.init(ID: Int(managedPerson.userID),
                  username: managedPerson.username,
                  firstName: managedPerson.firstName,
                  lastName: managedPerson.lastName,
                  displayName: managedPerson.displayName,
                  role: RemoteRole.viewer.slug,
                  siteID: Int(managedPerson.siteID),
                  linkedUserID: Int(managedPerson.linkedUserID),
                  avatarURL: managedPerson.avatarURL.flatMap { URL(string: $0) },
                  isSuperAdmin: managedPerson.isSuperAdmin)
    }
}
