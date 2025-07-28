import SwiftUI
import WordPressUI
import AsyncImageKit

struct AvatarView: View {
    let name: String
    var imageURL: URL?
    var size: CGFloat = 36
    var backgroundColor = Color(.systemBackground)

    @Environment(\.context) private var context

    var body: some View {
        Group {
            if let imageURL {
                let processedURL = context.preprocessAvatar?(imageURL, size) ?? imageURL
                CachedAsyncImage(url: processedURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Constants.Colors.background
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                placeholderView
            }
        }
        .overlay(
              RoundedRectangle(cornerRadius: size / 2)
                .stroke(Color(.opaqueSeparator).opacity(0.66), lineWidth: 0.5)
          )
    }

    private var placeholderView: some View {
        Circle()
            .fill(backgroundColor)
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(Color.primary.opacity(0.9))
            )
    }

    private var initials: String {
        let words = name.split(separator: " ")
        let initials = words.prefix(2).compactMap { $0.first?.uppercased() }.joined()
        return initials.isEmpty ? "?" : initials
    }
}
