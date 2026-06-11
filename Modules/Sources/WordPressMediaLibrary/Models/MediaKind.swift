import Foundation
import WordPressAPI
import WordPressAPIInternal

/// The enum itself is public so `MediaTrackerEvent.mediaLibraryFilterChanged(kind:)`
/// can carry it across the module boundary; the app-target analytics
/// adapter reads `rawValue` for its property dict.
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
