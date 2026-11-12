import SwiftUI

/// Pure grid rendering of media items. Takes the items and the aspect-ratio
/// mode directly (no view model) so it can back both the library grid and the
/// search-results grid.
struct MediaGridView: View {
    let items: [MediaGridItem]
    let isAspectRatioMode: Bool
    /// Returns whether a cell should render as tappable. Defaults to never,
    /// so callers that don't wire selection (e.g. the search grid) get a
    /// plain, non-interactive grid.
    var canSelect: (MediaGridItem) -> Bool = { _ in false }
    /// Invoked when a selectable cell is tapped.
    var onSelect: ((MediaGridItem) -> Void)?

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
                    cell(for: item)
                }
            }
            .padding(.top, spacing)
            .animation(.default, value: isAspectRatioMode)
        }
    }

    /// Wraps the cell in a plain `Button` when the item is selectable and a
    /// handler is wired. Placeholder cells (.fetching / .missing / .failed)
    /// stay non-tappable so taps never push a half-baked detail screen.
    @ViewBuilder private func cell(for item: MediaGridItem) -> some View {
        if let onSelect, canSelect(item) {
            Button {
                onSelect(item)
            } label: {
                MediaGridCell(item: item, isAspectRatioMode: isAspectRatioMode)
            }
            .buttonStyle(.plain)
        } else {
            MediaGridCell(item: item, isAspectRatioMode: isAspectRatioMode)
        }
    }
}
