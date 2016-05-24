import Foundation
import WordPressShared


// MARK: - Defines all of the peroperties a Person may have
//
protocol Person {
    /// Properties
    ///
    var ID: Int { get }
    var username: String { get }
    var firstName: String? { get }
    var lastName: String? { get }
    var displayName: String { get }
    var role: Role { get }
    var siteID: Int { get }
    var linkedUserID: Int { get }
    var avatarURL: NSURL? { get }
    var isSuperAdmin: Bool { get }
    var fullName: String { get }

    /// Initializers
    ///
    init(ID: Int,
         username: String,
         firstName: String?,
         lastName: String?,
         displayName: String,
         role: Role,
         siteID: Int,
         linkedUserID: Int,
         avatarURL: NSURL?,
         isSuperAdmin: Bool)
    init(managedPerson: ManagedPerson)
}

// MARK: - Specifies all of the Roles a Person may have
//
enum Role: String, Comparable, Equatable, CustomStringConvertible {
    case SuperAdmin     = "super-admin"
    case Admin          = "administrator"
    case Editor         = "editor"
    case Author         = "author"
    case Contributor    = "contributor"
    case Subscriber     = "subscriber"
    case Follower       = "follower"
    case Unsupported    = "unsupported"
}

// MARK: - Defines a Blog's User
//
struct User: Person {
    let ID: Int
    let username: String
    let firstName: String?
    let lastName: String?
    let displayName: String
    let role: Role
    let siteID: Int
    let linkedUserID: Int
    let avatarURL: NSURL?
    let isSuperAdmin: Bool
}

// MARK: - Defines a Blog's Follower
//
struct Follower: Person {
    let ID: Int
    let username: String
    let firstName: String?
    let lastName: String?
    let displayName: String
    let role: Role
    let siteID: Int
    let linkedUserID: Int
    let avatarURL: NSURL?
    let isSuperAdmin: Bool
}

// MARK: - Extensions
//
extension Person {
    var fullName: String {
        let first = firstName ?? String()
        let last = lastName ?? String()
        let separator = (first.isEmpty == false && last.isEmpty == false) ? " " : ""

        return "\(first)\(separator)\(last)"
    }

    static var isFollower: Bool {
        return self == Follower.self
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
        avatarURL = managedPerson.avatarURL.flatMap { NSURL(string: $0) }
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
        avatarURL = managedPerson.avatarURL.flatMap { NSURL(string: $0) }
        isSuperAdmin = managedPerson.isSuperAdmin
    }
}

extension Role {
    init(string: String) {
        guard let parsedRole = Role(rawValue: string) else {
            self = .Unsupported
            return
        }

        self = parsedRole
    }

    var color: UIColor {
        guard let color = self.dynamicType.colorsMap[self] else {
            fatalError()
        }

        return color
    }

    var description: String {
        return rawValue
    }

    var localizedName: String {
        guard let localized = self.dynamicType.localizedMap[self] else {
            fatalError()
        }

        return localized
    }

    // MARK: - Private Properties
    //
    private static let colorsMap = [
        SuperAdmin  : WPStyleGuide.People.superAdminColor,
        Admin       : WPStyleGuide.People.adminColor,
        Editor      : WPStyleGuide.People.editorColor,
        Author      : WPStyleGuide.People.authorColor,
        Contributor : WPStyleGuide.People.contributorColor,
        Subscriber  : WPStyleGuide.People.contributorColor,
        Follower    : WPStyleGuide.People.contributorColor,
        Unsupported : WPStyleGuide.People.contributorColor
    ]

    private static let localizedMap = [
        SuperAdmin  : NSLocalizedString("Super Admin", comment: "User role badge"),
        Admin       : NSLocalizedString("Admin", comment: "User role badge"),
        Editor      : NSLocalizedString("Editor", comment: "User role badge"),
        Author      : NSLocalizedString("Author", comment: "User role badge"),
        Contributor : NSLocalizedString("Contributor", comment: "User role badge"),
        Subscriber  : NSLocalizedString("Subscriber", comment: "User role badge"),
        Follower    : NSLocalizedString("Follower", comment: "User role badge"),
        Unsupported : NSLocalizedString("Unsupported", comment: "User role badge")
    ]
}



// MARK: - Operator Overloading

func ==<T : Person>(lhs: T, rhs: T) -> Bool {
    return lhs.ID == rhs.ID
        && lhs.username == rhs.username
        && lhs.firstName == rhs.firstName
        && lhs.lastName == rhs.lastName
        && lhs.displayName == rhs.displayName
        && lhs.role == rhs.role
        && lhs.siteID == rhs.siteID
        && lhs.linkedUserID == rhs.linkedUserID
        && lhs.avatarURL == rhs.avatarURL
        && lhs.isSuperAdmin == rhs.isSuperAdmin
        && lhs.dynamicType == rhs.dynamicType
}

func ==(lhs: Role, rhs: Role) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

func <(lhs: Role, rhs: Role) -> Bool {
    return lhs.rawValue < rhs.rawValue
}
