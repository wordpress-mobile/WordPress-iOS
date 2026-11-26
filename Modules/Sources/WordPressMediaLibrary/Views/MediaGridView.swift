import SwiftUI

/// Pure grid rendering of media items. Takes the items and the aspect-ratio
/// mode directly (no view model) so it can back both the library grid and the
/// search-results grid.
struct MediaGridView: View {
    let items: [MediaGridItem]
    let isAspectRatioMode: Bool

    private var spacing: CGFloat { isAspectRatioMode ? 8 : 2 }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVGrid(columns: columns(forWidth: proxy.size.width), spacing: spacing) {
                    ForEach(items) { item in
                        MediaGridCell(item: item, isAspectRatioMode: isAspectRatioMode)
                    }
                }
                .padding(.top, spacing)
                .animation(.default, value: isAspectRatioMode)
            }
        }
    }

    private func columns(forWidth width: CGFloat) -> [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: spacing),
            count: MediaGridLayout.columnCount(forWidth: width)
        )
    }
}

enum MediaGridLayout {
    /// Fits as many tiles of at least `minimumTileWidth` as the width allows,
    /// and never fewer than `minimumColumnCount`.
    static func columnCount(forWidth width: CGFloat) -> Int {
        let fitting = Int(((width + countingSpacing) / (minimumTileWidth + countingSpacing)).rounded(.down))
        return max(minimumColumnCount, fitting)
    }

    /// Close to the tile width of 4 columns on a portrait iPhone, so wider
    /// layouts keep tiles about the same size instead of scaling them up.
    static let minimumTileWidth: CGFloat = 96

    /// Both grid modes count columns with the larger (aspect ratio) spacing,
    /// so switching modes keeps every tile in its row and column, and tiles
    /// stay at least `minimumTileWidth` wide in both modes.
    static let countingSpacing: CGFloat = 8

    /// 4 columns on every iPhone in portrait, matching V1.
    static let minimumColumnCount = 4
}
