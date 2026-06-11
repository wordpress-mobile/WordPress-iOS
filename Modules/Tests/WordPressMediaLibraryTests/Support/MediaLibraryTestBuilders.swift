import Foundation
import WordPressAPI
import WordPressAPIInternal

@testable import WordPressMediaLibrary

/// Builds payload-less `MediaMetadataCollectionItem`s. These are the only items
/// constructible in a unit test: a payload-bearing item needs a `MediaDetails`
/// FFI object (Rust-backed) plus ~25 other FFI fields, which a pure test can't
/// build. Payload-less items map to `MediaGridItem.kind == nil`, which is what
/// `MediaGridItemKindTests` asserts.
enum MediaItemBuilder {
    static func failedNoData(id: Int64) -> MediaMetadataCollectionItem {
        MediaMetadataCollectionItem(id: id, parent: nil, menuOrder: nil, state: .failed(error: "boom"))
    }

    static func missing(id: Int64) -> MediaMetadataCollectionItem {
        MediaMetadataCollectionItem(id: id, parent: nil, menuOrder: nil, state: .missing)
    }
}
