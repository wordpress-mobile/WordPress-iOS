import Foundation
import WordPressAPI
import WordPressAPIInternal

/// The enum itself is public so `MediaTrackerEvent.mediaLibraryFilterChanged(kind:)`
/// can carry it across the module boundary; the app-target analytics
/// adapter reads `rawValue` for its property dict. The `MediaDetailsPayload`
/// initializer, the `MediaTypeParam` mapping, and the UI helpers
/// (`title` / `systemImageName`, added in Task 11) all stay module-internal
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

    var asMediaTypeParam: MediaTypeParam {
        switch self {
        case .image: .image
        case .video: .video
        case .audio: .audio
        case .document: .application
        }
    }
}
