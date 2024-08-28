import SwiftUI
import WordPressUI

struct SidebarProfileView: View {
    var username: String
    var displayName: String
    var avatar: URL?

    var body: some View {
        HStack {
            AvatarsView<Circle>(style: .single(avatar))

            VStack(alignment: .leading, spacing: 0) {
                Text(displayName)
                    .font(.callout.weight(.medium))
                Text("@\(username)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "gearshape")
                .foregroundColor(Color.secondary.opacity(0.7))
        }
    }
}
