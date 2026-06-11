import SwiftUI

/// Pure grid rendering of media items. Takes the items and the aspect-ratio
/// mode directly (no view model) so it can back both the library grid and the
/// search-results grid.
struct MediaGridView: View {
    let items: [MediaGridItem]
    let isAspectRatioMode: Bool

    @Environment(\.horizontalSizeClass) private var sizeClass

    private var spacing: CGFloat { isAspectRatioMode ? 8 : 2 }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: spacing),
            count: sizeClass == .regular ? 5 : 4
        )
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(items) { item in
                    MediaGridCell(item: item, isAspectRatioMode: isAspectRatioMode)
                }
            }
            .padding(.top, spacing)
            .animation(.default, value: isAspectRatioMode)
        }
    }
}
