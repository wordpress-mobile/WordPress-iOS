import SwiftUI
import WordPressUI

/// The small icon at the start of a row that stands for somewhere else on the web:
/// a referrer, or a link that was clicked.
///
/// The stats API names an icon for some of these and not others, so the glyph stands in
/// both for a row the API gave no icon for and for one whose icon can't be loaded. Every
/// row therefore reserves the same leading space and the titles stay aligned down the list.
///
/// It carries no accessibility label: the name of the site it belongs to sits right beside it.
struct StatsFaviconView: View {
    let iconURL: URL?

    var size: CGFloat = 24
    var cornerRadius: CGFloat = 4

    var body: some View {
        if let iconURL {
            CachedAsyncImage(url: iconURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                placeholderIcon
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            placeholderIcon
                .frame(width: size, height: size)
        }
    }

    private var placeholderIcon: some View {
        Image(systemName: "link")
    }
}
