import Foundation
import CoreGraphics
import WordPressAPI
import WordPressAPIInternal

/// Display model for a single grid cell.
struct MediaGridItem: Identifiable, Equatable {
    let id: Int64
    let kind: MediaKind?
    let displayTitle: String
    let thumbnailURL: URL? // image or video kind; the cell picks the right CachedAsyncImage initializer based on kind
    let aspectRatio: CGFloat? // image kind only; width / height
    let durationString: String? // video kind only
    let state: State
    let accessibilityLabel: String

    enum State: Equatable {
        case loaded(isUpToDate: Bool)
        case loading
        case error(message: String)
    }

    init(item: MediaMetadataCollectionItem) {
        switch item.state {
        case .fresh(let entity):
            self.init(media: entity.data, id: item.id, state: .loaded(isUpToDate: true))
        case .stale(let entity):
            self.init(media: entity.data, id: item.id, state: .loaded(isUpToDate: false))
        case .fetchingWithData(let entity):
            self.init(media: entity.data, id: item.id, state: .loading)
        case .failedWithData(let message, let entity):
            self.init(media: entity.data, id: item.id, state: .error(message: message))
        case .fetching, .missing:
            self.init(placeholderID: item.id, state: .loading)
        case .failed(let message):
            self.init(placeholderID: item.id, state: .error(message: message))
        }
    }

    /// Designated initializer for data-bearing states. Initializes every
    /// stored property exactly once.
    private init(media: MediaWithEditContext, id: Int64, state: State) {
        let payload = media.mediaDetails.parseAsMimeType(mimeType: media.mimeType)
        let kind = payload.flatMap(MediaKind.init(payload:)) ?? .document

        self.id = id
        self.kind = kind
        self.displayTitle = MediaGridItem.makeTitle(media: media)
        self.state = state
        self.accessibilityLabel = MediaGridItem.makeAccessibilityLabel(media: media, kind: kind)

        switch payload {
        case .image(let imageDetails):
            self.thumbnailURL = MediaThumbnailURL.pick(from: imageDetails, sourceUrl: media.sourceUrl)
            if imageDetails.width > 0, imageDetails.height > 0 {
                self.aspectRatio = CGFloat(imageDetails.width) / CGFloat(imageDetails.height)
            } else {
                self.aspectRatio = nil
            }
            self.durationString = nil
        case .video(let videoDetails):
            // For video, `thumbnailURL` carries the video file URL itself —
            // the cell renders it via `CachedAsyncImage(videoUrl:)`, which
            // extracts a frame for the thumbnail (V1 parity).
            self.thumbnailURL = URL(string: media.sourceUrl)
            self.aspectRatio = nil
            self.durationString = MediaGridDuration.string(forSeconds: videoDetails.length)
        case .audio, .document, .none:
            self.thumbnailURL = nil
            self.aspectRatio = nil
            self.durationString = nil
        }
    }

    /// Designated initializer for payload-less states. Initializes every
    /// stored property exactly once. The accessibility label branches on
    /// `state` because the same initializer covers both `.fetching` /
    /// `.missing` (genuinely loading) and `.failed` (error without payload):
    /// VoiceOver shouldn't hear "Loading media" while the cell shows an
    /// error icon.
    private init(placeholderID id: Int64, state: State) {
        self.id = id
        self.kind = nil // unknown: no payload to determine the media type
        self.displayTitle = ""
        self.thumbnailURL = nil
        self.aspectRatio = nil
        self.durationString = nil
        self.state = state
        switch state {
        case .error:
            self.accessibilityLabel = Strings.accessibilityErrorMedia
        case .loading, .loaded:
            self.accessibilityLabel = Strings.accessibilityLoadingMedia
        }
    }

    private static func makeTitle(media: MediaWithEditContext) -> String {
        let raw = (media.title.raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty { return raw }
        let slug = media.slug.trimmingCharacters(in: .whitespacesAndNewlines)
        if !slug.isEmpty { return slug }
        if let filename = filename(from: media.sourceUrl), !filename.isEmpty {
            return filename
        }
        return Strings.untitled
    }

    private static func makeAccessibilityLabel(media: MediaWithEditContext, kind: MediaKind) -> String {
        // `WpGmtDateTime` is a typealias for `Date` in the wordpress-rs Swift
        // binding, so `media.dateGmt` is already a proper Date — no string
        // parsing needed. The DateFormatter applies the user's locale + time
        // zone, so a UTC dateGmt renders as local time, matching the V1 cell
        // view-model's behavior.
        let date = MediaGridItem.accessibilityDateFormatter.string(from: media.dateGmt)
        switch kind {
        case .image:
            return String.localizedStringWithFormat(Strings.accessibilityLabelImage, date)
        case .video:
            return String.localizedStringWithFormat(Strings.accessibilityLabelVideo, date)
        case .audio:
            return String.localizedStringWithFormat(Strings.accessibilityLabelAudio, date)
        case .document:
            // V1 falls back to filename for documents; if filename can't be
            // derived, use the date so the row is still describable.
            let filenameOrDate = filename(from: media.sourceUrl) ?? date
            return String.localizedStringWithFormat(Strings.accessibilityLabelDocument, filenameOrDate)
        }
    }

    private static func filename(from sourceUrl: String) -> String? {
        guard let url = URL(string: sourceUrl) else { return nil }
        let last = url.lastPathComponent
        return last.isEmpty ? nil : last
    }

    private static let accessibilityDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()
}

#if DEBUG
extension MediaGridItem {
    /// Test-only: build an item with an explicit `kind`, bypassing FFI entity
    /// construction. Exposed via `@testable import`.
    init(testID id: Int64, kind: MediaKind?, state: State = .loaded(isUpToDate: true)) {
        self.id = id
        self.kind = kind
        self.displayTitle = ""
        self.thumbnailURL = nil
        self.aspectRatio = nil
        self.durationString = nil
        self.state = state
        self.accessibilityLabel = ""
    }
}
#endif
