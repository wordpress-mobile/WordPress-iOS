import Foundation
import WordPressShared

struct PeopleCellViewModel {
    let displayName: String
    let username: String
    let role: Role?
    let superAdmin: Bool
    let avatarURL: URL?

    init(person: Person, role: Role?) {
        self.displayName = person.displayName
        self.username = person.username
        self.role = role
        self.superAdmin = person.isSuperAdmin
        self.avatarURL = person.avatarURL as URL?
    }

    var usernameText: String {
        return "@" + username
    }

    var usernameColor: UIColor {
        return .text
    }

    var roleBorderColor: UIColor {
        return role?.color ?? WPStyleGuide.People.otherRoleColor
    }

    var roleBackgroundColor: UIColor {
        return role?.color ?? WPStyleGuide.People.otherRoleColor
    }

    var roleTextColor: UIColor {
        return WPStyleGuide.People.RoleBadge.textColor
    }

    var roleText: String {
        return role?.name ?? ""
    }

    var roleHidden: Bool {
        return roleText.isEmpty
    }

    var superAdminText: String {
        return NSLocalizedString("Super Admin", comment: "User role badge")
    }

    var superAdminBorderColor: UIColor {
        return superAdminBackgroundColor
    }

    var superAdminBackgroundColor: UIColor {
        return WPStyleGuide.People.superAdminColor
    }

    var superAdminHidden: Bool {
        return !superAdmin
    }
}
