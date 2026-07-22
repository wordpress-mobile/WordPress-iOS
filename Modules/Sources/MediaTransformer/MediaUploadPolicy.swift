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
    public let filePickerContentTypes: [UTType]

    /// Real upload allow/deny gate. Called by the materializer just before
    /// enqueue with the *effective* `(UTType, file-extension)` pair after
    /// any transform. App target typically backs this with
    /// `Blog.allowedFileTypes` + the default mobile-allowed-extensions list.
    public let isAllowedForUpload: @Sendable (_ contentType: UTType, _ fileExtension: String) -> Bool

    /// Resize the longest edge of images to at most this many pixels. `nil`
    /// means no cap. Applied before JPEG re-encode.
    public let imageMaxDimension: Int?

    /// JPEG quality for re-encoded images (0.0...1.0). Used both when
    /// resizing and when converting HEIC → JPEG.
    public let imageJpegQuality: Double

    /// If true, HEIC sources are converted to JPEG before upload.
    public let convertHEICToJPEG: Bool

    /// If true, an image whose EXIF orientation tag is non-identity is
    /// physically rotated upright and the tag reset to normal before upload, so
    /// viewers that ignore orientation metadata (older WordPress, some preview
    /// clients) still render it the right way up. An already-upright image (no
    /// tag, or orientation `1`) is left untouched — no needless recompress.
    public let normalizeImageOrientation: Bool

    /// Video duration cap in seconds. Over-duration videos are rejected
    /// (V1 parity, no trim).
    public let videoMaxDurationSeconds: TimeInterval?

    /// Longest-edge threshold, in pixels, that decides whether a video is
    /// re-encoded. A source at or under it (or an uncapped policy, `nil`) is
    /// remuxed without re-encoding when its codec allows, so it isn't transcoded
    /// just to be re-containered or to drop location metadata. A source that
    /// exceeds it is re-encoded with `videoExportPreset`.
    ///
    /// This is a **threshold, not a render size**: the actual output resolution
    /// of a re-encode is the preset's, not this value (`AVAssetExportSession`
    /// preset *names* can't express an arbitrary target size, and V1 sized video
    /// by preset too). Set it to match the resolution `videoExportPreset`
    /// produces — e.g. `1280` alongside `AVAssetExportPreset1280x720`. A mismatch
    /// (say `720` with a resolution-preserving preset like
    /// `AVAssetExportPresetHighestQuality`) re-encodes over-threshold sources
    /// without actually shrinking them.
    public let videoMaxDimension: Int?

    /// `AVAssetExportSession` preset name used **when a re-encode is needed**
    /// (the source exceeds `videoMaxDimension`, or can't be remuxed into
    /// `videoOutputContentType`). Determines the re-encode's output resolution
    /// **and** quality — e.g. `AVAssetExportPreset1280x720` caps the longest edge
    /// at 720p, `AVAssetExportPresetHighestQuality` preserves the source size.
    public let videoExportPreset: String

    /// Output container UTType for re-exported videos. Default
    /// `.mpeg4Movie`. Drives the file extension of the materialized temp
    /// file and the effective MIME type the validator checks against.
    public let videoOutputContentType: UTType

    /// The "Remove Location" setting. If true, GPS EXIF is stripped from
    /// images and identifying metadata (via `AVMetadataItemFilter.forSharing()`)
    /// is filtered from re-exported videos before upload.
    public let stripLocation: Bool

    public init(
        filePickerContentTypes: [UTType],
        isAllowedForUpload: @escaping @Sendable (UTType, String) -> Bool,
        imageMaxDimension: Int?,
        imageJpegQuality: Double,
        convertHEICToJPEG: Bool,
        normalizeImageOrientation: Bool,
        videoMaxDurationSeconds: TimeInterval?,
        videoMaxDimension: Int?,
        videoExportPreset: String,
        videoOutputContentType: UTType,
        stripLocation: Bool
    ) {
        self.filePickerContentTypes = filePickerContentTypes
        self.isAllowedForUpload = isAllowedForUpload
        self.imageMaxDimension = imageMaxDimension
        self.imageJpegQuality = imageJpegQuality
        self.convertHEICToJPEG = convertHEICToJPEG
        self.normalizeImageOrientation = normalizeImageOrientation
        self.videoMaxDurationSeconds = videoMaxDurationSeconds
        self.videoMaxDimension = videoMaxDimension
        self.videoExportPreset = videoExportPreset
        self.videoOutputContentType = videoOutputContentType
        self.stripLocation = stripLocation
    }
}
