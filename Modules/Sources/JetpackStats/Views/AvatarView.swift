import SwiftUI
import WordPressUI
import AsyncImageKit

struct AvatarView: View {
    let name: String
    var imageURL: URL?
    var size: CGFloat = 36
    var backgroundColor = Color(.systemBackground)

    @Environment(\.context) private var context
    @ScaledMetric(relativeTo: .body) private var scaledSize: CGFloat = 36

    var body: some View {
        let avatarSize = min(scaledSize * (size / 36), 72)

        Group {
            if let imageURL {
                let processedURL = context.preprocessAvatar?(imageURL, avatarSize) ?? imageURL
                CachedAsyncImage(url: processedURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Constants.Colors.background
                }
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
            } else {
                placeholderView
            }
        }
        .overlay(
              RoundedRectangle(cornerRadius: avatarSize / 2)
                .stroke(Color(.opaqueSeparator).opacity(0.66), lineWidth: 0.5)
          )
    }

    @ViewBuilder
    private var placeholderView: some View {
        let avatarSize = min(scaledSize * (size / 36), 72)
        Circle()
            .fill(backgroundColor)
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Text(initials)
                    .font(.system(size: avatarSize * 0.4, weight: .medium))
                    .foregroundColor(Color.primary.opacity(0.9))
            )
    }

    private var initials: String {
        let words = name.split(separator: " ")
        let initials = words.prefix(2).compactMap { $0.first?.uppercased() }.joined()
        return initials.isEmpty ? "?" : initials
    }
}
