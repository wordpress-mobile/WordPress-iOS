import SwiftUI

struct UserListItem: View {

    @ScaledMetric(relativeTo: .headline)
    var height: CGFloat = 48

    @Environment(\.sizeCategory)
    var sizeCategory

    var user: DisplayUser

    var body: some View {
        NavigationLink {
            UserDetailView(user: user, userIsAdministrator: true)
        } label: {
            HStack(alignment: .top) {
                if !sizeCategory.isAccessibilityCategory {
                    if let profilePhotoUrl = user.profilePhotoUrl {
                        UserProfileImage(size: CGSize(width: height, height: height), url: profilePhotoUrl)
                    }
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
    UserListItem(user: DisplayUser.MockUser)
}
