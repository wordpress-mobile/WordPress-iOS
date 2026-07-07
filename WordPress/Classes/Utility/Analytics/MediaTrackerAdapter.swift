import Foundation
import WordPressData
import WordPressMediaLibrary
import WordPressShared

/// App-target adapter that bridges the module's `MediaTracker` to
/// `WPAppAnalytics` while preserving V1 analytics property fidelity
/// (`tap_source`, `tab_source`, `is_v2`).
@MainActor
struct MediaTrackerAdapter: MediaTracker {
    let blog: Blog
    let baseProperties: [String: Any]

    func track(_ event: MediaTrackerEvent) {
        let stat: WPAnalyticsStat
        var properties = baseProperties

        switch event {
        case .mediaLibraryOpened:
            stat = .openedMediaLibrary

        case .mediaLibraryFilterChanged(let kind):
            stat = .siteMediaFilterChanged
            properties["filter_kind"] = kind?.rawValue ?? "all"

        case .mediaLibrarySearched(let queryLength):
            stat = .siteMediaSearched
            properties["query_length"] = queryLength

        case .mediaLibraryGridModeToggled(let isAspectRatio):
            stat = .siteMediaGridModeToggled
            properties["mode"] = isAspectRatio ? "aspect_ratio" : "square"

        case .mediaLibraryAdded(let source, let kind):
            handleAddedMedia(source: source, kind: kind)
            return

        case .mediaLibraryUploadRetried:
            stat = .mediaLibraryUploadMediaRetried
        }

        WPAppAnalytics.track(stat, properties: properties, blog: blog)
    }

    private func handleAddedMedia(source: MediaUploadSource, kind: MediaKind) {
        switch source {
        case .photoLibrary, .camera, .otherApps:
            guard let resolvedStat = uploadAddedStat(source: source, kind: kind) else {
                // .audio / .document map to no event — V1 parity.
                return
            }
            var props = baseProperties
            // V1 attaches media_origin via selectionMethod: full_screen_picker for
            // the photo library / camera, document_picker for the Files app.
            switch source {
            case .photoLibrary, .camera:
                props["media_origin"] = "full_screen_picker"
            case .otherApps:
                props["media_origin"] = "document_picker"
            case .stockPhotos, .imagePlayground:
                break
            }
            WPAppAnalytics.track(resolvedStat, properties: props, blog: blog)

        case .stockPhotos:
            // External sources fire only for image kind — non-image .remoteURL
            // (which the materializer rejects) must NOT log a photo-added event
            // at enqueue time.
            guard kind == .image else { return }
            var props = baseProperties
            props["media_origin"] = "full_screen_picker"
            // Bare selection-time call — matches V1's
            // SiteMediaAddMediaMenuController.swift:127 (no properties / blog).
            WPAnalytics.track(.stockMediaUploaded)
            // Contextual ...ViaStockPhotos with baseProperties + media_origin + blog.
            WPAppAnalytics.track(.mediaLibraryAddedPhotoViaStockPhotos, properties: props, blog: blog)

        case .imagePlayground:
            // V1 doesn't emit a ...ViaImagePlayground event; preserved for parity.
            return
        }
    }

    private func uploadAddedStat(source: MediaUploadSource, kind: MediaKind) -> WPAnalyticsStat? {
        switch (source, kind) {
        case (.photoLibrary, .image): return .mediaLibraryAddedPhotoViaDeviceLibrary
        case (.photoLibrary, .video): return .mediaLibraryAddedVideoViaDeviceLibrary
        case (.camera, .image): return .mediaLibraryAddedPhotoViaCamera
        case (.camera, .video): return .mediaLibraryAddedVideoViaCamera
        case (.otherApps, .image): return .mediaLibraryAddedPhotoViaOtherApps
        case (.otherApps, .video): return .mediaLibraryAddedVideoViaOtherApps
        // Unreachable from `handleAddedMedia`; kept for switch exhaustiveness.
        case (.stockPhotos, _), (.imagePlayground, _): return nil
        case (_, .audio), (_, .document): return nil
        }
    }
}
