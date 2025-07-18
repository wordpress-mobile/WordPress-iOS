import SwiftUI
import WordPressUI
import AsyncImageKit

struct AvatarView: View {
    let name: String
    let imageURL: URL?
    let size: CGFloat

    init(name: String, imageURL: URL? = nil, size: CGFloat = 36) {
        self.name = name
        self.imageURL = imageURL
        self.size = size
    }

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
            .fill(Color(.systemBackground))
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
