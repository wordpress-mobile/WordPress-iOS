import Foundation
import WordPressAPI
import WordPressAPIInternal

/// The enum itself is public so `MediaTrackerEvent.mediaLibraryFilterChanged(kind:)`
/// can carry it across the module boundary; the app-target analytics
/// adapter reads `rawValue` for its property dict. The `MediaDetailsPayload`
/// initializer, the `MediaTypeParam` mapping, and the UI helpers
/// (`title` / `systemImageName`) all stay module-internal
/// — they're used only inside the module and in `@testable` tests, so
/// there's no reason to leak `WordPressAPIInternal` types through the
/// public surface.
public enum MediaKind: String, CaseIterable, Hashable, Sendable {
    case image, video, audio, document

    init?(payload: MediaDetailsPayload) {
        switch payload {
        case .image: self = .image
        case .video: self = .video
        case .audio: self = .audio
        case .document: self = .document
        }
    }

    /// Maps the V2 grid filter selection to the wordpress-rs REST query
    /// parameter. **Known narrowing for `.document`:** V1's "Documents"
    /// bucket includes attachments the system classifies as `text/*` (e.g.
    /// `.txt`, `.md`) alongside the `application/*` MIME family, because V1
    /// builds its filter locally against Core Data's `mediaTypeString`. V2
    /// goes through the wordpress-rs `MediaListFilter.mediaType` parameter,
    /// which is a single optional `MediaTypeParam` — we can't OR
    /// `.application` and `.text` in one query without an upstream
    /// wordpress-rs change. V2 ships with the narrower `.application`-only
    /// document bucket; full V1 parity here depends on a wordpress-rs
    /// change to support multi-value media-type filtering.
    var asMediaTypeParam: MediaTypeParam {
        switch self {
        case .image: .image
        case .video: .video
        case .audio: .audio
        case .document: .application
        }
    }
}

// MARK: - UI helpers
//
// These properties live in the same file as the enum but in their own
// extension so they're easy to spot and so the base enum (used by the
// public analytics surface) doesn't pull in localized strings unnecessarily.

extension MediaKind {
    var title: String {
        switch self {
        case .image: Strings.filterImages
        case .video: Strings.filterVideos
        case .audio: Strings.filterAudio
        case .document: Strings.filterDocuments
        }
    }

    var systemImageName: String {
        switch self {
        case .image: "photo"
        case .video: "video"
        case .audio: "waveform"
        case .document: "folder"
        }
    }
}
