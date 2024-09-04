import SwiftUI
import WordPressUI

struct SidebarProfileView: View {
    var username: String
    var displayName: String
    var avatar: URL?

    var body: some View {
        HStack {
            AvatarsView<Circle>(style: .single(avatar), diameter: 30)

            VStack(alignment: .leading, spacing: 0) {
                Text(displayName)
                    .font(.subheadline.weight(.medium))
                Text("@\(username)")
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
