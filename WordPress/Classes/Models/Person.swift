import Foundation
import CoreData

typealias People = [Person]

struct Person {
    let ID: Int
    let username: String
    let firstName: String
    let lastName: String
    let displayName: String
    let role: Role
    let pending: Bool
    let siteID: Int
    let avatarURL: NSURL?

    var avatar: UIImage? {
        return nil
    }

    enum Role: Int {
        case SuperAdmin
        case Admin
        case Editor
        case Author
        case Contributor
        case Unsupported

        init(string: String) {
            switch string {
            case "Administrator":
                self = .Admin
            case "Editor":
                self = .Editor
            case "Author":
                self = .Author
            case "Contributor":
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
    }
}
