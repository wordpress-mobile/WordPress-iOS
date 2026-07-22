import Foundation

/// The failures `MediaTransformer` can throw while planning or writing a
/// transform. Scoped to what the engine itself produces — image validation and
/// encode, GPS/location strip, and video export. File access, downloads, and the
/// upload allow-list belong to the caller that drives the transformer, and carry
/// their own errors.
public enum MediaTransformerError: LocalizedError {
    case durationCapExceeded
    case invalidImageData
    case imageEncodeFailed
    case locationStripFailed
    case videoExportFailed(underlyingError: Error)
    case videoExportSessionUnavailable

    public var errorDescription: String? {
        switch self {
        case .durationCapExceeded: return Strings.durationCap
        case .invalidImageData: return Strings.invalidImage
        case .imageEncodeFailed: return Strings.imageEncode
        case .locationStripFailed: return Strings.locationStripFailed
        case .videoExportFailed(let underlyingError):
            return String.localizedStringWithFormat(
                Strings.videoExport,
                underlyingError.localizedDescription
            )
        case .videoExportSessionUnavailable: return Strings.videoExportNoExporter
        }
    }
}

// MARK: - Localized strings

/// The messages `MediaTransformerError` renders. They live with the error (not
/// in `WordPressMediaLibrary`'s `Strings`) so this module stays self-contained.
/// The `NSLocalizedString` keys are unchanged from their previous home, so
/// GlotPress extraction is unaffected.
private enum Strings {
    static let durationCap = NSLocalizedString(
        "mediaLibrary.upload.error.durationCap",
        value: "This video is longer than your site allows.",
        comment: "Error shown when a picked video exceeds the duration cap configured for the blog."
    )
    static let invalidImage = NSLocalizedString(
        "mediaLibrary.upload.error.invalidImage",
        value: "The selected file isn't a valid image.",
        comment: "Error shown when picked or downloaded bytes do not decode as an image."
    )
    static let imageEncode = NSLocalizedString(
        "mediaLibrary.upload.error.imageEncode",
        value: "Couldn't convert the photo for upload.",
        comment: "Error shown when re-encoding an image (e.g. HEIC to JPEG) fails before upload."
    )
    static let locationStripFailed = NSLocalizedString(
        "mediaLibrary.upload.error.locationStrip",
        value: "Couldn't remove the location from the photo for upload.",
        comment:
            "Error shown when stripping GPS/location metadata from an image fails and the Remove Location setting is on."
    )
    static let videoExport = NSLocalizedString(
        "mediaLibrary.upload.error.videoExport",
        value: "Couldn't prepare the video for upload: %1$@",
        comment:
            "Error shown when AVAssetExportSession fails before upload. %1$@ is the underlying error description."
    )
    static let videoExportNoExporter = NSLocalizedString(
        "mediaLibrary.upload.error.videoExport.noExporter",
        value: "No exporter is available for the selected video quality.",
        comment:
            "Error shown when no AVAssetExportSession can be created for the configured export preset."
    )
}
