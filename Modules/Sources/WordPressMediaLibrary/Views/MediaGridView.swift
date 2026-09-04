import SwiftUI

/// Pure grid layout for media items. Takes the items and the aspect-ratio mode
/// directly (no view model) and a per-item cell builder, so it can back both
/// the library grid (rich cells: detail push, selection badges, pending-delete
/// overlays) and the search-results grid (detail-push cells).
struct MediaGridView<Cell: View>: View {
    let items: [MediaGridItem]
    let isAspectRatioMode: Bool
    @ViewBuilder let cell: (MediaGridItem) -> Cell

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
                    cell(item)
                }
            }
            .padding(.top, spacing)
            .animation(.default, value: isAspectRatioMode)
        }
    }
}
