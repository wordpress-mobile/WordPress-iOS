import SwiftUI

struct TopListAuthorRowView: View {
    let item: TopListItem.Author

    var body: some View {
        HStack(spacing: Constants.step0_5) {
            AvatarView(name: item.name, imageURL: item.avatarURL)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.body)
                    .foregroundColor(.primary)

                if let role = item.role {
                    Text(role)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .lineLimit(1)
        }
    }
}
