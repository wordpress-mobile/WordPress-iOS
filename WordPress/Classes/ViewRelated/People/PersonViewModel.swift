import Foundation

struct PersonViewModel {
    let displayName: String
    let username: String
    let firstName: String?
    let lastName: String?
    let role: Person.Role
    let avatarURL: NSURL?
    let detailsEditable: Bool

    init(person: Person, blog: Blog) {
        self.displayName = person.displayName
        self.username = person.username
        self.firstName = person.firstName
        self.lastName = person.lastName
        self.role = person.role
        self.avatarURL = person.avatarURL

        // Editing profile details for others is only available for self-hosted
        self.detailsEditable = !blog.isHostedAtWPcom
    }

    var usernameText: String {
        return "@" + username
    }

    var roleText: String {
        return role.localizedName()
    }

    var firstNameCellHidden: Bool {
        return !detailsEditable
    }

    var lastNameCellHidden: Bool {
        return !detailsEditable
    }

    var displayNameCellHidden: Bool {
        return !detailsEditable
    }
}