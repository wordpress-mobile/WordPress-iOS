import Foundation
import CoreData
import WordPressKit

public typealias Person = RemotePerson

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

// MARK: - Extensions
//
extension Person {
    init(managedPerson: ManagedPerson) {
        self.init(ID: Int(managedPerson.userID),
                  username: managedPerson.username,
                  firstName: managedPerson.firstName,
                  lastName: managedPerson.lastName,
                  displayName: managedPerson.displayName,
                  role: Role(string: managedPerson.role),
                  siteID: Int(managedPerson.siteID),
                  linkedUserID: Int(managedPerson.linkedUserID),
                  avatarURL: managedPerson.avatarURL.flatMap { URL(string: $0) },
                  isSuperAdmin: managedPerson.isSuperAdmin)
    }
}

extension User {
    init(managedPerson: ManagedPerson) {
        ID = Int(managedPerson.userID)
        username = managedPerson.username
        firstName = managedPerson.firstName
        lastName = managedPerson.lastName
        displayName = managedPerson.displayName
        role = Role(string: managedPerson.role)
        siteID = Int(managedPerson.siteID)
        linkedUserID = Int(managedPerson.linkedUserID)
        avatarURL = managedPerson.avatarURL.flatMap { URL(string: $0) }
        isSuperAdmin = managedPerson.isSuperAdmin
    }
}

extension Follower {
    init(managedPerson: ManagedPerson) {
        ID = Int(managedPerson.userID)
        username = managedPerson.username
        firstName = managedPerson.firstName
        lastName = managedPerson.lastName
        displayName = managedPerson.displayName
        role = Role.Follower
        siteID = Int(managedPerson.siteID)
        linkedUserID = Int(managedPerson.linkedUserID)
        avatarURL = managedPerson.avatarURL.flatMap { URL(string: $0) }
        isSuperAdmin = managedPerson.isSuperAdmin
    }
}

extension Viewer {
    init(managedPerson: ManagedPerson) {
        ID = Int(managedPerson.userID)
        username = managedPerson.username
        firstName = managedPerson.firstName
        lastName = managedPerson.lastName
        displayName = managedPerson.displayName
        role = Role.Viewer
        siteID = Int(managedPerson.siteID)
        linkedUserID = Int(managedPerson.linkedUserID)
        avatarURL = managedPerson.avatarURL.flatMap { URL(string: $0) }
        isSuperAdmin = managedPerson.isSuperAdmin
    }
}

extension Role {
    var color: UIColor {
        guard let color = type(of: self).colorsMap[self] else {
            fatalError()
        }

        return color
    }

    var localizedName: String {
        guard let localized = type(of: self).localizedMap[self] else {
            fatalError()
        }

        return localized
    }

    // MARK: - Static Properties
    //
    static let inviteRoles: [Role] = [.Follower, .Admin, .Editor, .Author, .Contributor]
    static let inviteRolesForPrivateSite: [Role] = [.Viewer, .Admin, .Editor, .Author, .Contributor]

    // MARK: - Private Properties
    //
    fileprivate static let colorsMap = [
        SuperAdmin: WPStyleGuide.People.superAdminColor,
        Admin: WPStyleGuide.People.adminColor,
        Editor: WPStyleGuide.People.editorColor,
        Author: WPStyleGuide.People.authorColor,
        Contributor: WPStyleGuide.People.contributorColor,
        Subscriber: WPStyleGuide.People.contributorColor,
        Follower: WPStyleGuide.People.contributorColor,
        Viewer: WPStyleGuide.People.contributorColor,
        Unsupported: WPStyleGuide.People.contributorColor
    ]

    fileprivate static let localizedMap = [
        SuperAdmin: NSLocalizedString("Super Admin", comment: "User role badge"),
        Admin: NSLocalizedString("Admin", comment: "User role badge"),
        Editor: NSLocalizedString("Editor", comment: "User role badge"),
        Author: NSLocalizedString("Author", comment: "User role badge"),
        Contributor: NSLocalizedString("Contributor", comment: "User role badge"),
        Subscriber: NSLocalizedString("Subscriber", comment: "User role badge"),
        Follower: NSLocalizedString("Follower", comment: "User role badge"),
        Viewer: NSLocalizedString("Viewer", comment: "User role badge"),
        Unsupported: NSLocalizedString("Unsupported", comment: "User role badge")
    ]
}
