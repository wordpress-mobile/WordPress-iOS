import SwiftUI
import WordPressUI

struct SidebarProfileView: View {
    @ObservedObject var account: WPAccount

    var body: some View {
        HStack {
            let avatarURL = account.avatarURL.flatMap(URL.init(string:))
            AvatarView<Circle>(style: .single(avatarURL), diameter: 30)

            VStack(alignment: .leading, spacing: 0) {
                if let displayName = account.displayName {
                    Text(displayName)
                        .font(.subheadline.weight(.medium))
                }
                Text("@\(account.username)")
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
