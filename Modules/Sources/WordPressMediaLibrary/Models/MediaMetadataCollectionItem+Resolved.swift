import Foundation
import WordPressAPI
import WordPressAPIInternal

extension MediaMetadataCollectionItem {
    /// Extracts the `MediaWithEditContext` from data-bearing states.
    /// Returns nil for placeholder states (.fetching / .missing / .failed)
    /// where no media payload is carried.
    var resolvedMedia: MediaWithEditContext? {
        switch state {
        case .fresh(let entity): return entity.data
        case .stale(let entity): return entity.data
        case .fetchingWithData(let entity): return entity.data
        case .failedWithData(_, let entity): return entity.data
        case .fetching, .missing, .failed: return nil
        }
    }
}
