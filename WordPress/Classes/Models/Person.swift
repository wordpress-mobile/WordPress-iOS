import Foundation
import WordPressShared

// MARK: - Typealiases
//
typealias People = [Person]


// MARK: - Person Encapsulates all of the properties a Blog's User may have
//
struct Person: Equatable {
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
    
    enum Role: Int, Comparable, Equatable, CustomStringConvertible {
        case SuperAdmin
        case Admin
        case Editor
        case Author
        case Contributor
        case Unsupported
        
        static let roles : [Role] = [.SuperAdmin, .Admin, .Editor, .Author, .Contributor]
    }
}



// MARK: - Person Helper Methods
//
extension Person {
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

    var fullName: String {
        let first = firstName ?? String()
        let last = lastName ?? String()
        let separator = (first.isEmpty == false && last.isEmpty == false) ? " " : ""
        
        return "\(first)\(separator)\(last)"
    }
}



// MARK: - Role Helpers
//
extension Person.Role {
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



// MARK: - Operator Overloading
//
func ==(lhs: Person, rhs: Person) -> Bool {
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
}

func ==(lhs: Person.Role, rhs: Person.Role) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

func <(lhs: Person.Role, rhs: Person.Role) -> Bool {
    return lhs.rawValue < rhs.rawValue
}
