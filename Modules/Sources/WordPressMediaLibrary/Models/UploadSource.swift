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
}

extension UploadSource {
    /// Fraction of the overall upload progress allocated to the
    /// materialization stage. 0.05 for on-device sources; the upcoming
    /// remote case (Free Photo Library, M6) will return 0.20.
    var materializationProgressWeight: Double {
        switch self {
        case .photoLibrary, .cameraImage, .cameraVideo, .file:
            return 0.05
        }
    }
}
