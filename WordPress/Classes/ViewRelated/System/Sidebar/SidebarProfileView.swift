import SwiftUI
import WordPressData
import WordPressUI

struct SidebarProfileView: View {
    @ObservedObject var account: WPAccount
    @ObservedObject private var accountAvatar = AccountAvatar.shared

    @ScaledMetric private var avatarDiameter: CGFloat = 30

    var body: some View {
        HStack {
            Image(uiImage: accountAvatar.image ?? .gravatarPlaceholderImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: avatarDiameter, height: avatarDiameter)
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                }

            VStack(alignment: .leading, spacing: 0) {
                if let displayName = account.displayName {
                    Text(displayName)
                        .font(.subheadline.weight(.medium))
                }
                Text(verbatim: "@\(account.username)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "gearshape")
                .font(.title3)
                .foregroundColor(Color.secondary)
        }
    }
}
