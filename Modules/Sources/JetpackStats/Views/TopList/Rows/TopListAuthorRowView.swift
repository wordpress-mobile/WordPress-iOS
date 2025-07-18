import SwiftUI

struct TopListAuthorRowView: View {
    let item: TopListData.Author
    let showDetails: Bool

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: item.name, imageURL: item.avatarURL)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if showDetails, let role = item.role {
                    Text(role)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
