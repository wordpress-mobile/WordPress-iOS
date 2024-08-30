import SwiftUI
import WordPressUI

struct SidebarProfileView: View {
    @ObservedObject var account: WPAccount

    var body: some View {
        HStack {
            let avatarURL: String? = account.avatarURL
            AvatarsView<Circle>(style: .single(avatarURL.flatMap(URL.init)), diameter: 30)

            VStack(alignment: .leading, spacing: 0) {
                Text(account.displayName)
                    .font(.subheadline.weight(.medium))
                Text("@\(account.username)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "gearshape")
                .foregroundColor(Color.secondary.opacity(0.7))
        }
    }
}
