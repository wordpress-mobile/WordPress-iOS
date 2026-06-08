import Foundation
import UIKit
import UniformTypeIdentifiers

/// Picker-output payload that the materializer consumes. Variants carry the
/// source-of-origin needed for analytics — `MediaLibraryViewModel` reads
/// the case to fire `.mediaLibraryAdded(source:kind:)` *before* enqueueing,
/// so the actor never has to derive analytics from picker shape.
enum UploadSource: @unchecked Sendable {
    /// `PHPickerResult.itemProvider` plus its `suggestedName` (typically
    /// "IMG_1234" or nil) and a UTType hint from the picker selection.
    case photoLibrary(itemProvider: NSItemProvider, suggestedName: String?, hint: UTType)

    /// Captured image from the camera. `Date` is the capture moment used
    /// for the filename pattern `IMG_<yyyy-MM-dd HH-mm-ss>.jpg`.
    case cameraImage(UIImage, capturedAt: Date)

    /// Captured video file from the camera, already at a temp URL.
    case cameraVideo(URL, capturedAt: Date)

    /// File-importer URL. Materializer reads it under
    /// `startAccessingSecurityScopedResource()`.
    case file(URL)

    /// Remote-URL source for external pickers (Stock Photos). The
    /// materializer downloads bytes via `RemoteDownloader` before dispatching
    /// to the image / GIF / disallowed branches.
    case remoteURL(RemoteURL)

    /// Image Playground (iOS 18.1+) returns a local file URL in our app
    /// sandbox. The materializer copies bytes without security-scoped access
    /// and dispatches to `materializeFileImage`.
    case imagePlayground(URL, suggestedName: String)
}

extension UploadSource {
    /// Internal carrier for `.remoteURL`. The public boundary type
    /// `ExternalRemoteMedia` is converted to this in the view model before
    /// enqueueing — keeps `UploadSource` module-internal.
    struct RemoteURL: Sendable {
        let url: URL
        let suggestedName: String
        let contentType: UTType
        let caption: String?
    }
}

extension UploadSource {
    /// Fraction of the overall upload progress allocated to the
    /// materialization stage. On-device sources are fast to materialize
    /// relative to the upload itself.
    var materializationProgressWeight: Double {
        switch self {
        case .photoLibrary, .cameraImage, .cameraVideo, .file, .imagePlayground:
            return 0.05
        case .remoteURL:
            // Remote sources download the full file during materialization, then
            // upload the same bytes, so split the bar evenly between the two.
            // The real download-vs-upload time ratio varies by network, so this
            // weight only affects how smoothly the row advances, not correctness.
            return 0.5
        }
    }

    /// Best-effort media kind derived from the picker payload before the
    /// upload is materialized, used for the pre-enqueue analytics event and
    /// the initial Uploads-row icon. The materializer later derives the
    /// authoritative kind from the post-transform content type.
    var estimatedKind: MediaKind {
        switch self {
        case .photoLibrary(_, _, let hint):
            return MediaKind(estimating: hint)
        case .cameraImage:
            return .image
        case .cameraVideo:
            return .video
        case .file(let url):
            let contentType =
                (try? url.resourceValues(forKeys: [.contentTypeKey]))?.contentType
                ?? UTType(filenameExtension: url.pathExtension)
            return contentType.map { MediaKind(estimating: $0) } ?? .document
        case .remoteURL(let remote):
            return MediaKind(estimating: remote.contentType)
        case .imagePlayground:
            return .image
        }
    }
}
