import Foundation

struct PeopleCellViewModel {
    let displayName: String
    let username: String
    let role: Person.Role
    let pending: Bool
    let avatar: UIImage

    init(person: Person) {
        self.displayName = person.displayName
        self.username = person.username
        self.role = person.role
        self.pending = person.pending
        self.avatar = person.avatar ?? UIImage(named: "gravatar")!
    }

    var usernameText: String {
        return "@" + username
    }

    var roleBorderColor: UIColor {
        return role.color()
    }

    var roleBackgroundColor: UIColor {
        return pending ? WPStyleGuide.People.RoleBadge.textColor : role.color()
    }

    var roleTextColor: UIColor {
        return pending ? role.color() : WPStyleGuide.People.RoleBadge.textColor
    }

    var roleText: String {
        if pending {
            return String(format: NSLocalizedString("%@ - pending", comment: "User role indicator, when there's a pending invite. Placeholder is role (e.g. Admin, Editor,...)"), role.localizedName())
        } else {
            return role.localizedName()
        }
    }
}
