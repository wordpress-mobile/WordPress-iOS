import SwiftUI

struct UserListItem: View {

    @ScaledMetric(relativeTo: .headline)
    var height: CGFloat = 48

    @Environment(\.dynamicTypeSize)
    var dynamicTypeSize

    let user: DisplayUser
    let isCurrentUser: Bool
    let userService: UserServiceProtocol
    let applicationTokenListDataProvider: ApplicationTokenListDataProvider

    var body: some View {
        NavigationLink {
            UserDetailsView(user: user, isCurrentUser: isCurrentUser, userService: userService, applicationTokenListDataProvider: applicationTokenListDataProvider)
        } label: {
            HStack(alignment: .top) {
                if !dynamicTypeSize.isAccessibilitySize {
                    AvatarView(style: .single(user.profilePhotoUrl), placeholderImage: Image("gravatar").resizable())
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
    UserListItem(user: DisplayUser.MockUser, isCurrentUser: true, userService: MockUserProvider(), applicationTokenListDataProvider: StaticTokenProvider(tokens: .success(.testTokens)))
}
