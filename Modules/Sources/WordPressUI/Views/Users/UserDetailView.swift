import SwiftUI

/// Subclass this and register it with the SwiftUI `.environmentObject` method
/// to perform user management actions
open class UserManagementActionDispatcher: ObservableObject {
    @Published
    open var error: Error?

    open func setNewPassword(id: Int32, newPassword: String) {}
    open func deleteUser(id: Int32, reassigningPostsTo userId: Int32) {}

    public init() {}
}

struct UserDetailView: View {

    let user: DisplayUser

    let userIsAdministrator: Bool

    @EnvironmentObject
    var actionDispatcher: UserManagementActionDispatcher

    var body: some View {
        Form {
            Section(Strings.nameSectionTitle) {
                LabeledContent(Strings.roleFieldTitle, value: user.role)
                LabeledContent(Strings.firstNameFieldTitle, value: user.firstName)
                LabeledContent(Strings.lastNameFieldTitle, value: user.lastName)
                LabeledContent(Strings.nicknameFieldTitle, value: user.handle)
                LabeledContent(Strings.displayNameFieldTitle, value: user.displayName)
            }

            Section(Strings.contactInfoSectionTitle) {
                LabeledContent(Strings.emailAddressFieldTitle, value: user.emailAddress)
                if let website = user.websiteUrl {
                    LabeledContent(Strings.websiteFieldTitle, value: website)
                }
            }

            Section(Strings.aboutUserSectionTitle) {
                LabeledContent(Strings.bioFieldTitle, value: user.biography ?? "")
                if let profilePhotoUrl = user.profilePhotoUrl {
                    LabeledContent(Strings.profilePictureFieldTitle) {
                        UserProfileImage(size: CGSize(width: 96, height: 96), url: profilePhotoUrl)
                    }
                }
            }

            if userIsAdministrator {
                Section(Strings.accountManagementSectionTitle) {
                    Button(Strings.setNewPasswordActionTitle) {
                        actionDispatcher.setNewPassword(id: user.id, newPassword: "foo")
                    }

                    Button(Strings.deleteUserActionTitle, role: .destructive) {
                        actionDispatcher.deleteUser(id: user.id, reassigningPostsTo: 42) // TODO
                    }
                }

            }
        }.navigationTitle(user.displayName)
    }

    enum Strings {
        static let nameSectionTitle = NSLocalizedString(
            "userdetail.name-section-title",
            value: "Name",
            comment: "The 'Name' section of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let contactInfoSectionTitle = NSLocalizedString(
            "userdetail.contact-info-section-title",
            value: "Contact Info",
            comment: "The 'Contact Info' section of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let aboutUserSectionTitle = NSLocalizedString(
            "userdetail.about-user-section-title",
            value: "About the User",
            comment: "The 'About the user' section of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let accountManagementSectionTitle = NSLocalizedString(
            "userdetail.account-management-section-title",
            value: "Account Management",
            comment: "The 'Account Management' section of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let roleFieldTitle = NSLocalizedString(
            "userdetail.role-field-title",
            value: "Role",
            comment: "The 'Role' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let firstNameFieldTitle = NSLocalizedString(
            "userdetail.first-name-field-title",
            value: "First Name",
            comment: "The 'First Name' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let lastNameFieldTitle = NSLocalizedString(
            "userdetail.last-name-field-title",
            value: "Last Name",
            comment: "The 'Last Name' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let nicknameFieldTitle = NSLocalizedString(
            "userdetail.nickname-field-title",
            value: "Nickname",
            comment: "The 'Nickname' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let displayNameFieldTitle = NSLocalizedString(
            "userdetail.displayname-field-title",
            value: "Display Name",
            comment: "The 'Display Name publicly as' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let emailAddressFieldTitle = NSLocalizedString(
            "userdetail.email-address-field-title",
            value: "Email Address",
            comment: "The 'Email' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let websiteFieldTitle = NSLocalizedString(
            "userdetail.website-field-title",
            value: "Website",
            comment: "The 'Website' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let bioFieldTitle = NSLocalizedString(
            "userdetail.bio-field-title",
            value: "Biographical Info",
            comment: "The 'Biographical Info' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let profilePictureFieldTitle = NSLocalizedString(
            "userdetail.profile-picture-field-title",
            value: "Profile Picture",
            comment: "The 'Profile Picture' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let setNewPasswordActionTitle  = NSLocalizedString(
            "userdetail.set-new-password-action-title",
            value: "Set New Password",
            comment: "The 'Set New Password' button on the user profile – matches what's in /wp-admin/profile.php"
        )

        static let sendPasswordResetEmailActionTitle  = NSLocalizedString(
            "userdetail.send-password-reset-email-action-title",
            value: "Send Password Reset Email",
            comment: "The 'Send Password Reset Email' button on the user profile – matches what's in /wp-admin/profile.php"
        )

        static let deleteUserActionTitle  = NSLocalizedString(
            "userdetail.delete-user-action-title",
            value: "Delete User",
            comment: "The 'Delete User' button on the user profile – matches what's in /wp-admin/profile.php"
        )
    }
}

#Preview {
    NavigationStack {
        UserDetailView(user: DisplayUser.MockUser, userIsAdministrator: true)
    }
}
