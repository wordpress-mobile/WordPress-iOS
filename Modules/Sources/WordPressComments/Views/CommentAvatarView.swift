import AsyncImageKit
import SwiftUI

/// The 40pt circular author avatar shared by the list row and the detail header.
struct CommentAvatarView: View {
    let url: URL?

    var body: some View {
        CachedAsyncImage(url: url) { image in
            image.resizable()
        } placeholder: {
            Color(.secondarySystemBackground)
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }
}
