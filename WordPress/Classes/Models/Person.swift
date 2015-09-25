import Foundation
import CoreData

typealias People = [Person]

struct Person {
    let ID: Int
    let username: String
    let firstName: String?
    let lastName: String?
    let displayName: String
    let role: Role
    let pending: Bool
    let siteID: Int
    let avatarURL: NSURL?

    var avatar: UIImage? {
        return nil
    }

    enum Role: Int, Comparable, CustomStringConvertible {
        case SuperAdmin
        case Admin
        case Editor
        case Author
        case Contributor
        case Unsupported

        init(string: String) {
            switch string {
            case "administrator":
                self = .Admin
            case "editor":
                self = .Editor
            case "author":
                self = .Author
            case "contributor":
                self = .Contributor
            default:
                self = .Unsupported
            }
        }

        func color() -> UIColor {
            switch self {
            case .SuperAdmin:
                return WPStyleGuide.People.superAdminColor
            case .Admin:
                return WPStyleGuide.People.adminColor
            case .Editor:
                return WPStyleGuide.People.editorColor
            case .Author:
                return WPStyleGuide.People.authorColor
            case .Contributor:
                return WPStyleGuide.People.contributorColor
            case .Unsupported:
                return WPStyleGuide.People.contributorColor
            }
        }

        func localizedName() -> String {
            switch self {
            case .SuperAdmin:
                return NSLocalizedString("Super Admin", comment: "User role badge")
            case .Admin:
                return NSLocalizedString("Admin", comment: "User role badge")
            case .Editor:
                return NSLocalizedString("Editor", comment: "User role badge")
            case .Author:
                return NSLocalizedString("Author", comment: "User role badge")
            case .Contributor:
                return NSLocalizedString("Contributor", comment: "User role badge")
            case .Unsupported:
                return NSLocalizedString("Unsupported", comment: "User role badge")
            }
        }

        var description: String {
            switch self {
            case .SuperAdmin:
                return "super-admin"
            case .Admin:
                return "administrator"
            case .Editor:
                return "editor"
            case .Author:
                return "author"
            case .Contributor:
                return "contributor"
            default:
                return "unsupported"
            }
        }
    }
}

func <(lhs: Person.Role, rhs: Person.Role) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

class ManagedPerson: NSManagedObject {
    @NSManaged var avatarURL: String?
    @NSManaged var displayName: String
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var role: String
    @NSManaged var siteID: Int32
    @NSManaged var userID: Int32
    @NSManaged var username: String

    @NSManaged var blog: Blog

    func updateWith(person: Person) {
        avatarURL = person.avatarURL?.absoluteString
        displayName = person.displayName
        firstName = person.firstName
        lastName = person.lastName
        role = String(person.role)
        siteID = Int32(person.siteID)
        userID = Int32(person.ID)
        username = person.username
    }
}

extension Person {
    init(managedPerson: ManagedPerson) {
        ID = Int(managedPerson.userID)
        username = managedPerson.username
        firstName = managedPerson.firstName
        lastName = managedPerson.lastName
        displayName = managedPerson.displayName
        role = Role(string: managedPerson.role)
        pending = false
        siteID = Int(managedPerson.siteID)
        avatarURL = managedPerson.avatarURL.flatMap { NSURL(string: $0) }
    }
}

extension Person: Equatable {}

func ==(lhs: Person, rhs: Person) -> Bool {
    return lhs.ID == rhs.ID
        && lhs.username == rhs.username
        && lhs.firstName == rhs.firstName
        && lhs.lastName == rhs.lastName
        && lhs.displayName == rhs.displayName
        && lhs.role == rhs.role
        && lhs.pending == rhs.pending
        && lhs.siteID == rhs.siteID
        && lhs.avatarURL == rhs.avatarURL
}

