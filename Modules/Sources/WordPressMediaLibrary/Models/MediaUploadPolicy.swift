import Foundation
import UniformTypeIdentifiers

/// Upload policy injected by the app target. The module honors this struct
/// but never derives it — `Blog.allowedFileTypes`, user-media settings, etc.
/// stay on the app side. Picker affordance and upload validation are split
/// because the materializer validates the effective post-transform type and
/// extension, not just the source file the picker exposed.
public struct MediaUploadPolicy: Sendable {
    /// UTTypes the document picker (`.fileImporter`) offers. May include
    /// broad fallbacks like `.content` when the server allow-list is empty.
    /// **Not** the upload validator. Photos and camera pickers do not read
    /// this field — they have their own hard-coded image/video filters.
    let filePickerContentTypes: [UTType]

    /// Real upload allow/deny gate. Called by the materializer just before
    /// enqueue with the *effective* `(UTType, file-extension)` pair after
    /// any transform. App target typically backs this with
    /// `Blog.allowedFileTypes` + the default mobile-allowed-extensions list.
    let isAllowedForUpload: @Sendable (_ contentType: UTType, _ fileExtension: String) -> Bool

    /// Resize the longest edge of images to at most this many pixels. `nil`
    /// means no cap. Applied before JPEG re-encode.
    let imageMaxDimension: Int?

    /// JPEG quality for re-encoded images (0.0...1.0). Used both when
    /// resizing and when converting HEIC → JPEG.
    let imageJpegQuality: Double

    /// If true, HEIC sources are converted to JPEG before upload.
    let convertHEICToJPEG: Bool

    /// Video duration cap in seconds. Over-duration videos are rejected
    /// (V1 parity, no trim).
    let videoMaxDurationSeconds: TimeInterval?

    /// `AVAssetExportSession` preset name. Controls quality only.
    let videoExportPreset: String

    /// Output container UTType for re-exported videos. Default
    /// `.mpeg4Movie`. Drives the file extension of the materialized temp
    /// file and the effective MIME type the validator checks against.
    let videoOutputContentType: UTType

    /// If true, strip GPS EXIF before upload.
    let stripImageLocation: Bool

    public init(
        filePickerContentTypes: [UTType],
        isAllowedForUpload: @escaping @Sendable (UTType, String) -> Bool,
        imageMaxDimension: Int?,
        imageJpegQuality: Double,
        convertHEICToJPEG: Bool,
        videoMaxDurationSeconds: TimeInterval?,
        videoExportPreset: String,
        videoOutputContentType: UTType,
        stripImageLocation: Bool
    ) {
        self.filePickerContentTypes = filePickerContentTypes
        self.isAllowedForUpload = isAllowedForUpload
        self.imageMaxDimension = imageMaxDimension
        self.imageJpegQuality = imageJpegQuality
        self.convertHEICToJPEG = convertHEICToJPEG
        self.videoMaxDurationSeconds = videoMaxDurationSeconds
        self.videoExportPreset = videoExportPreset
        self.videoOutputContentType = videoOutputContentType
        self.stripImageLocation = stripImageLocation
    }
}
