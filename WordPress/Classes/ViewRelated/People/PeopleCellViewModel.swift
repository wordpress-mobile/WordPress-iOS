import Foundation
import WordPressShared

struct PeopleCellViewModel {
    let displayName: String
    let username: String
    let role: Role
    let superAdmin: Bool
    let avatarURL: URL?

    init(person: Person) {
        self.displayName = person.displayName
        self.username = person.username
        self.role = person.role
        self.superAdmin = person.isSuperAdmin
        self.avatarURL = person.avatarURL as URL?
    }

    var usernameText: String {
        return "@" + username
    }

    var roleBorderColor: UIColor {
        return role.color
    }

    var roleBackgroundColor: UIColor {
        return role.color
    }

    var roleTextColor: UIColor {
        return WPStyleGuide.People.RoleBadge.textColor
    }

    var roleText: String {
        return role.localizedName
    }

    var superAdminText: String {
        return Role.SuperAdmin.localizedName
    }

    var superAdminBorderColor: UIColor {
        return superAdminBackgroundColor
    }

    var superAdminBackgroundColor: UIColor {
        return Role.SuperAdmin.color
    }

    var superAdminHidden: Bool {
        return !superAdmin
    }
}
