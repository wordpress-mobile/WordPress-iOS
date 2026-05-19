import Foundation
import UniformTypeIdentifiers
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

    /// Coarse, best-effort classification of a content type before an upload
    /// is materialized. Defaults to `.document` for anything that isn't
    /// recognizably image, video, or audio. The materializer derives the
    /// authoritative kind from the post-transform content type.
    init(estimating contentType: UTType) {
        if contentType.conforms(to: .image) {
            self = .image
        } else if contentType.conforms(to: .movie) {
            self = .video
        } else if contentType.conforms(to: .audio) {
            self = .audio
        } else {
            self = .document
        }
    }

    /// Derives the kind directly from a MIME-type string. Mirrors the
    /// prefix logic in wordpress-rs' `MediaDetails::parse_as_mime_type`
    /// (`image/*`, `video/*`, `audio/*`, else document) but avoids the
    /// FFI call and full-payload JSON deserialization those callers pay
    /// for when only the kind tag is needed.
    static func from(mimeType: String) -> MediaKind {
        if mimeType.hasPrefix("image/") { return .image }
        if mimeType.hasPrefix("video/") { return .video }
        if mimeType.hasPrefix("audio/") { return .audio }
        return .document
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
