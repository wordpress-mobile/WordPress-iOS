import Foundation
import WordPressAPI
import WordPressAPIInternal

/// Snapshot model the V2 detail screen reads and binds to. Built once from
/// a `MediaWithEditContext` at detail-VM init, then mutated in place when a
/// per-field save returns its server response. Keeping the merge logic
/// against a Swift-native value type avoids rebuilding a 27-arg UniFFI
/// struct on every save.
struct MediaDetailDisplayModel: Equatable, Sendable {
    let id: Int64
    var title: String?
    var caption: String
    var description: String
    var altText: String
    let mimeType: String
    let sourceUrl: String
    let mediaDetails: MediaDetails
    let dateGmt: Date
    let slug: String
    let kind: MediaKind

    init(media: MediaWithEditContext) {
        self.id = media.id
        self.title = media.title.raw
        self.caption = media.caption.raw
        self.description = media.description.raw
        self.altText = media.altText
        self.mimeType = media.mimeType
        self.sourceUrl = media.sourceUrl
        self.mediaDetails = media.mediaDetails
        self.dateGmt = media.dateGmt
        self.slug = media.slug
        self.kind = .from(mimeType: media.mimeType)
    }

    /// Adopts the server's value for one field after a successful save. The
    /// other fields stay at their local values so a concurrent different-
    /// field save can't clobber siblings by returning a stale snapshot.
    mutating func apply(_ field: MediaEditableField, fromServer server: MediaWithEditContext) {
        switch field {
        case .title: self.title = server.title.raw
        case .caption: self.caption = server.caption.raw
        case .description: self.description = server.description.raw
        case .altText: self.altText = server.altText
        }
    }
}
