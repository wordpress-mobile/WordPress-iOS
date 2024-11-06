import SwiftUI

struct UserListItem: View {

    @ScaledMetric(relativeTo: .headline)
    var height: CGFloat = 48

    @Environment(\.sizeCategory)
    var sizeCategory

    private let user: DisplayUser
    private let userProvider: UserDataProvider
    private let actionDispatcher: UserManagementActionDispatcher

    init(user: DisplayUser, userProvider: UserDataProvider, actionDispatcher: UserManagementActionDispatcher) {
        self.user = user
        self.userProvider = userProvider
        self.actionDispatcher = actionDispatcher
    }

    var body: some View {
        NavigationLink {
            UserDetailView(user: user, userProvider: userProvider, actionDispatcher: actionDispatcher)
        } label: {
            HStack(alignment: .top) {
                if !sizeCategory.isAccessibilityCategory {
                    UserProfileImage(size: height, url: user.profilePhotoUrl)
                }
                VStack(alignment: .leading) {
                    Text(user.displayName).font(.headline)
                    Text(user.handle).font(.body).foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    UserListItem(user: DisplayUser.MockUser, userProvider: MockUserProvider(), actionDispatcher: UserManagementActionDispatcher())
}
