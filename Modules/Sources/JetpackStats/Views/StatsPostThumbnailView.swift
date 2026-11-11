import SwiftUI
import WordPressUI

/// The small square at the start of a Posts & Pages row: the post's featured image, or
/// the glyph that tells a post apart from a page when it has none.
///
/// The glyph also stands in while the image is loading and stays put if the image can't be
/// loaded at all, so a row is never left with an empty square. It gives way the moment the
/// image arrives — a featured image with a transparent background would otherwise show the
/// glyph through the middle of it for good.
///
/// It carries no accessibility label: the post's title sits right beside it.
struct StatsPostThumbnailView: View {
    let item: TopListItem.Post

    @ObservedObject var store: PostThumbnailStore

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 32

    private var cornerRadius: CGFloat {
        size / 5
    }

    var body: some View {
        let thumbnailURL = item.numericPostID.flatMap { store.thumbnails[$0] }

        Group {
            if let thumbnailURL {
                CachedAsyncImage(url: thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    typeGlyph
                }
            } else {
                typeGlyph
            }
        }
        .frame(width: size, height: size)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: item.numericPostID) {
            if let postID = item.numericPostID {
                store.requestThumbnail(forPostID: postID)
            }
        }
    }

    private var typeGlyph: some View {
        Image(systemName: item.typeSystemImage)
            .font(.system(size: size / 2))
            .foregroundStyle(.secondary)
    }
}
