import SwiftUI

struct UserDetailView: View {

    private let userProvider: UserDataProvider
    private let actionDispatcher: UserManagementActionDispatcher
    let user: DisplayUser

    @StateObject
    var viewModel: UserDetailViewModel

    @Environment(\.dismiss)
    var dismissAction: DismissAction

    init(user: DisplayUser, userProvider: UserDataProvider, actionDispatcher: UserManagementActionDispatcher) {
        self.user = user
        self.userProvider = userProvider
        self.actionDispatcher = actionDispatcher
        _viewModel = StateObject(wrappedValue: UserDetailViewModel(userProvider: userProvider))
    }

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

            if viewModel.currentUserCanModifyUsers {
                Section(Strings.accountManagementSectionTitle) {
                    NavigationLink {
                        UserChangePasswordView(viewModel: passwordChangeViewModel)
                    } label: {
                        Text(Strings.setNewPasswordActionTitle)
                    }

                    NavigationLink {
                        // Pass this view's dismiss action, because if we delete a user, we want that screen *and* this one gone
                        UserDeleteView(user: user, userProvider: userProvider, actionDispatcher: actionDispatcher, dismiss: dismissAction)
                    } label: {
                        Text(Strings.deleteUserActionTitle)
                    }
                }
            }
        }
        .navigationTitle(user.displayName)
        .task {
            await viewModel.loadCurrentUserRole()
        }
    }

    var passwordChangeViewModel: UserChangePasswordViewModel {
        UserChangePasswordViewModel(user: user, actionDispatcher: actionDispatcher)
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
        UserDetailView(user: DisplayUser.MockUser, userProvider: MockUserProvider(), actionDispatcher: UserManagementActionDispatcher())
    }
}
