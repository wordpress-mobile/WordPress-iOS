import Foundation
import WordPressAPI
import WordPressAPIInternal

/// Filter state for the Media Library grid. Hashable so it can drive
/// `.task(id: viewModel.filter)` — when any field changes, SwiftUI
/// cancels the outstanding refresh/observer tasks and re-runs them
/// against the freshly-rebuilt collection.
struct MediaGridFilter: Hashable {
    var kind: MediaKind? // nil = all kinds
    var search: String // empty = no constraint

    static let initial = MediaGridFilter(kind: nil, search: "")

    func with(kind: MediaKind?) -> Self {
        var copy = self
        copy.kind = kind
        return copy
    }

    func with(search: String) -> Self {
        var copy = self
        copy.search = search
        return copy
    }

    func asMediaListFilter() -> MediaListFilter {
        MediaListFilter(
            search: search.isEmpty ? nil : search,
            mediaType: kind?.asMediaTypeParam
        )
    }
}
