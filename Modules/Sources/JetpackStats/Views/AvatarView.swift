import SwiftUI
import WordPressUI
import AsyncImageKit

struct AvatarView: View {
    let name: String
    var imageURL: URL?
    var size: CGFloat = 36
    var backgroundColor = Color(.systemBackground)

    var body: some View {
        if let imageURL {
            CachedAsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                placeholderView
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        Circle()
            .fill(backgroundColor)
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(Color.secondary)
            )
    }

    private var initials: String {
        let words = name.split(separator: " ")
        let initials = words.prefix(2).compactMap { $0.first?.uppercased() }.joined()
        return initials.isEmpty ? "?" : initials
    }
}
