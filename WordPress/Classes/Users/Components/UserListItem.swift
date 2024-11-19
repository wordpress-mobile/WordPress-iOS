import SwiftUI

struct UserListItem: View {

    @ScaledMetric(relativeTo: .headline)
    var height: CGFloat = 48

    @Environment(\.dynamicTypeSize)
    var dynamicTypeSize

    let user: DisplayUser
    let userService: UserServiceProtocol
    let applicationTokenListDataProvider: ApplicationTokenListDataProvider

    var body: some View {
        NavigationLink {
            UserDetailsView(user: user, userService: userService, applicationTokenListDataProvider: applicationTokenListDataProvider)
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
    UserListItem(user: DisplayUser.MockUser, userService: MockUserProvider(), applicationTokenListDataProvider: StaticTokenProvider(tokens: .success(.testTokens)))
}
