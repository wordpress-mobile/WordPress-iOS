import SwiftUI

struct UserDetailsView: View {

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
                            .foregroundStyle(Color.red)
                    }
                }
            }
        }
        .task {
            await viewModel.loadCurrentUserRole()
        }
    }

    var passwordChangeViewModel: UserChangePasswordViewModel {
        UserChangePasswordViewModel(user: user, actionDispatcher: actionDispatcher)
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
            "userdetail.accountManagementSectionTitle",
            value: "Account Management",
            comment: "The 'Account Management' section of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let roleFieldTitle = NSLocalizedString(
            "userdetail.roleFieldTitle",
            value: "Role",
            comment: "The 'Role' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let emailAddressFieldTitle = NSLocalizedString(
            "userdetail.emailAddressFieldTitle",
            value: "Email Address",
            comment: "The 'Email' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let websiteFieldTitle = NSLocalizedString(
            "userdetail.websiteFieldTitle",
            value: "Website",
            comment: "The 'Website' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let bioFieldTitle = NSLocalizedString(
            "userdetail.bioFieldTitle",
            value: "Biographical Info",
            comment: "The 'Biographical Info' field of the user profile – matches what's in /wp-admin/profile.php"
        )

        static let setNewPasswordActionTitle  = NSLocalizedString(
            "userdetail.setNewPasswordActionTitle",
            value: "Set New Password",
            comment: "The 'Set New Password' button on the user profile – matches what's in /wp-admin/profile.php"
        )

        static let sendPasswordResetEmailActionTitle  = NSLocalizedString(
            "userdetail.sendPasswordResetEmailActionTitle",
            value: "Send Password Reset Email",
            comment: "The 'Send Password Reset Email' button on the user profile – matches what's in /wp-admin/profile.php"
        )

        static let deleteUserActionTitle  = NSLocalizedString(
            "userdetail.deleteUserActionTitle",
            value: "Delete User",
            comment: "The 'Delete User' button on the user profile – matches what's in /wp-admin/profile.php"
        )
    }
}

private struct UserDetailLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: LabeledContentStyleConfiguration) -> some View {
        LabeledContent(configuration)
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
