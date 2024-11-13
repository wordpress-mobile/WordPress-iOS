import SwiftUI

struct UserDetailsView: View {

    private let userProvider: UserDataProvider
    private let actionDispatcher: UserManagementActionDispatcher
    let user: DisplayUser

    @State private var presentPasswordAlert: Bool = false {
        didSet {
            newPassword = ""
            newPasswordConfirmation = ""
        }
    }
    @State private var newPassword: String = ""
    @State private var newPasswordConfirmation: String = ""

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
            VStack {
                UserProfileImage(size: 96, url: user.profilePhotoUrl)
                Text(user.displayName)
                    .font(.title)
                Text(user.handle)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .listRowInsets(.zero)

            Section {
                makeRow(title: Strings.roleFieldTitle, content: user.role)
                makeRow(title: Strings.emailAddressFieldTitle, content: user.emailAddress, link: user.emailAddress.asEmail())
                if let website = user.websiteUrl, !website.isEmpty {
                    makeRow(title: Strings.websiteFieldTitle, content: website, link: URL(string: website))
                }
                if let biography = user.biography, !biography.isEmpty {
                    makeRow(title: Strings.bioFieldTitle, content: biography)
                }
            }

            if viewModel.currentUserCanModifyUsers {
                Section(Strings.accountManagementSectionTitle) {
                    Button(Strings.setNewPasswordActionTitle) {
                        presentPasswordAlert = true
                    }

                    NavigationLink {
                        // Pass this view's dismiss action, because if we delete a user, we want that screen *and* this one gone
                        UserDeleteView(user: user, userProvider: userProvider, actionDispatcher: actionDispatcher, dismiss: dismissAction)
                    } label: {
                        Text(Strings.deleteUserActionTitle)
                            .foregroundStyle(Color.red)
                    }
                }
            }
        }
        .alert(
            Strings.setNewPasswordActionTitle,
            isPresented: $presentPasswordAlert,
            actions: {
                SecureField(Strings.newPasswordPlaceholder, text: $newPassword)
                SecureField(Strings.newPasswordConfirmationPlaceholder, text: $newPasswordConfirmation)
                Button(Strings.updatePasswordButton) {
                    Task {
                        try await self.actionDispatcher.setNewPassword(id: user.id, newPassword: newPassword)
                    }
                }
                .disabled(newPassword.isEmpty || newPassword != newPasswordConfirmation)
                Button(role: .cancel) {
                    presentPasswordAlert = false
                } label: {
                    // TODO: Replace with `SharedStrings.Button.cancel`
                    Text(NSLocalizedString("shared.button.cancel", value: "Cancel", comment: "A shared button title used in different contexts"))
                }
            },
            message: {
                Text(Strings.newPasswordAlertMessage)
            }
        )
        .task {
            await viewModel.loadCurrentUserRole()
        }
    }

    func makeRow(title: String, content: String, link: URL? = nil) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
            if let link {
                Link(content, destination: link)
            } else {
                Text(content)
            }
        }
    }

    enum Strings {
        static let accountManagementSectionTitle = NSLocalizedString(
            "userDetails.accountManagementSectionTitle",
            value: "Account Management",
            comment: "The 'Account Management' section of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let roleFieldTitle = NSLocalizedString(
            "userDetails.roleFieldTitle",
            value: "Role",
            comment: "The 'Role' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let emailAddressFieldTitle = NSLocalizedString(
            "userDetails.emailAddressFieldTitle",
            value: "Email Address",
            comment: "The 'Email' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let websiteFieldTitle = NSLocalizedString(
            "userDetails.websiteFieldTitle",
            value: "Website",
            comment: "The 'Website' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let bioFieldTitle = NSLocalizedString(
            "userDetails.bioFieldTitle",
            value: "Biographical Info",
            comment: "The 'Biographical Info' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let setNewPasswordActionTitle  = NSLocalizedString(
            "userDetails.setNewPasswordActionTitle",
            value: "Set New Password",
            comment: "The 'Set New Password' button on the user profile – matches what's in /wp-admin/profile.php"
        )

        static let deleteUserActionTitle  = NSLocalizedString(
            "userDetails.deleteUserActionTitle",
            value: "Delete User",
            comment: "The 'Delete User' button on the user profile – matches what's in /wp-admin/profile.php"
        )

        static let newPasswordAlertMessage = NSLocalizedString(
            "userDetails.newPasswordAlertMessage",
            value: "Enter a new password for this user",
            comment: "The message in the alert that appears when setting a new password on the user profile"
        )

        static let newPasswordPlaceholder = NSLocalizedString(
            "userDetails.textField.placeholder.newPassword",
            value: "New password",
            comment: "The placeholder text for the 'New Password' field on the user profile"
        )

        static let newPasswordConfirmationPlaceholder = NSLocalizedString(
            "userDetails.textField.placeholder.newPasswordConfirmation",
            value: "Confirm new password",
            comment: "The placeholder text for the 'Confirm New Password' field on the user profile"
        )

        static let updatePasswordButton = NSLocalizedString(
            "userDetails.button.updatePassword",
            value: "Update",
            comment: "The 'Update' button to set a new password on the user profile"
        )
    }
}

#Preview {
    NavigationStack {
        UserDetailsView(user: DisplayUser.MockUser, userProvider: MockUserProvider(), actionDispatcher: UserManagementActionDispatcher())
    }
}

private extension String {
    func asEmail() -> URL? {
        let str = "mailto:\(self)"
        let range = NSRange(str.startIndex..<str.endIndex, in: str)

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
              let result = detector.firstMatch(in: str, range: range)
            else { return nil }

        return result.url
    }
}
