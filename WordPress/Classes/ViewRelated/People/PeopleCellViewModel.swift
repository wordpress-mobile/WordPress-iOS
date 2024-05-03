import Foundation
import WordPressShared
import DesignSystem

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

    var usernameHidden: Bool {
        return username.isEmpty
    }

    var usernameColor: UIColor {
        return .text
    }

    var roleBackgroundColor: UIColor {
        return role?.backgroundColor ?? .DS.Background.secondary
    }

    var roleTextColor: UIColor {
        return role?.textColor ?? .DS.Foreground.primary
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

    var superAdminBackgroundColor: UIColor {
        return .DS.Foreground.primary
    }

    var superAdminHidden: Bool {
        return !superAdmin
    }
}
