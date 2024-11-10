import SwiftUI

struct UserListItem: View {

    @ScaledMetric(relativeTo: .headline)
    var height: CGFloat = 48

    @Environment(\.dynamicTypeSize)
    var dynamicTypeSize

    private let user: DisplayUser
    private let userService: UserServiceProtocol

    init(user: DisplayUser, userService: UserServiceProtocol) {
        self.user = user
        self.userService = userService
    }

    var body: some View {
        NavigationLink {
            UserDetailsView(user: user, userService: userService)
        } label: {
            HStack(alignment: .top) {
                if !dynamicTypeSize.isAccessibilitySize {
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
    UserListItem(user: DisplayUser.MockUser, userService: MockUserProvider())
}
