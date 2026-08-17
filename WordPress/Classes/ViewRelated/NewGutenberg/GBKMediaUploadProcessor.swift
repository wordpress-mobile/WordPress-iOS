import Foundation
import GutenbergKit
import UniformTypeIdentifiers
import WordPressData

/// Processes media files picked in the GutenbergKit editor before upload,
/// applying the app's Media settings (image optimization, max upload size,
/// image quality, video resolution, and location stripping).
///
/// Assigned to `GutenbergKit.EditorViewController.mediaUploadDelegate`, which
/// holds it weakly and invokes it off the main actor, so the type is `Sendable`
/// and snapshots the `Blog`-derived values it needs at initialization.
final class GBKMediaUploadProcessor: MediaUploadDelegate, Sendable {
    private let videoDurationLimit: TimeInterval?
    private let allowableFileExtensions: Set<String>
    private let makeMediaSettings: @Sendable () -> MediaSettings

    /// Raster image types the WordPress REST API reliably accepts. Other image
    /// formats (e.g. HEIC) are converted to JPEG during processing, mirroring
    /// `ItemProviderMediaExporter`.
    ///
    /// - Note: SVG is deliberately absent. It is web-safe, but it is a vector
    ///   format that ImageIO cannot decode or encode, so it never reaches the
    ///   exporter — `processFile` returns it unchanged (see below).
    private static let webSafeImageTypes: Set<UTType> = [.png, .jpeg, .gif]

    /// A fixed ID for the temporary directory exports are written to, so every
    /// upload reuses the same directory instead of creating a new one.
    ///
    /// Stable across launches: a directory orphaned by a crash is reused rather
    /// than accumulating alongside a new one.
    private static let exportDirectoryID = UUID(uuidString: "1D8A4E5C-1F3B-4E7A-9C2D-6B0F8A5E3C71")!

    @MainActor
    convenience init(blog: Blog) {
        // HEIC isn't supported when uploading an image, so we filter it out,
        // mirroring `MediaImportService`.
        var allowedFileTypes = blog.allowedFileTypes
        allowedFileTypes.remove("heic")

        self.init(
            videoDurationLimit: blog.videoDurationLimit,
            allowableFileExtensions: allowedFileTypes
        )
    }

    init(
        videoDurationLimit: TimeInterval?,
        allowableFileExtensions: Set<String>,
        makeMediaSettings: @escaping @Sendable () -> MediaSettings = { MediaSettings() }
    ) {
        self.videoDurationLimit = videoDurationLimit
        self.allowableFileExtensions = allowableFileExtensions
        self.makeMediaSettings = makeMediaSettings
    }

    // MARK: - MediaUploadDelegate

    func processFile(at url: URL, mimeType: String, filename: String) async throws -> ProcessedProxyFile {
        let expected = try MediaURLExporter.expectedExport(with: url)
        let settings = makeMediaSettings()

        switch expected {
        case .gif:
            // GIFs are uploaded unchanged; processing would only copy the file.
            return .original
        case .other:
            // Non-media files are uploaded unchanged, but enforce the site's
            // allowed file extensions, mirroring `MediaURLExporter.exportURL`.
            if let fileExtension = url.typeIdentifierFileExtension,
                !MediaImportService.defaultAllowableFileExtensions.contains(fileExtension),
                !allowableFileExtensions.isEmpty,
                !allowableFileExtensions.contains(fileExtension)
            {
                throw MediaURLExporter.URLExportError.unsupportedFileType
            }
            return .original
        case .image:
            let type = url.typeIdentifier.flatMap(UTType.init)

            // SVG conforms to `UTType.image`, so it lands here, but ImageIO
            // cannot decode or encode it: the export would fail rather than
            // produce a file. Upload it unchanged, like a GIF.
            if type == .svg {
                return .original
            }

            // Skip the export when nothing would change the file: no
            // downscaling, no location stripping, and no format conversion.
            //
            // This is narrower than "processing changes nothing". With
            // optimization off, `imageQualityForUpload` is still `.high`, so a
            // web-safe image that reaches the exporter is re-encoded at that
            // quality even though `imageSizeForUpload` leaves its dimensions
            // alone. That mirrors `MediaImportService`, which maps the same
            // settings the same way.
            if !settings.imageOptimizationEnabled,
                !settings.removeLocationSetting,
                let type,
                Self.webSafeImageTypes.contains(type)
            {
                return .original
            }
        case .video:
            // Always process video to apply the export preset, duration
            // limit, and location stripping.
            break
        }

        let export = try await makeExporter(for: url, settings: settings).export()

        guard let mimeType = export.url.typeIdentifier.flatMap(UTType.init)?.preferredMIMEType else {
            throw MediaURLExporter.URLExportError.unknownFileUTI
        }
        return .processed(export.url, mimeType: mimeType, filename: export.url.lastPathComponent)
    }

    // MARK: - Exporter configuration

    /// Builds an exporter configured from the app's Media settings, mirroring
    /// the option mapping in `MediaImportService`.
    private func makeExporter(for url: URL, settings: MediaSettings) -> MediaURLExporter {
        let exporter = MediaURLExporter(url: url)
        // GutenbergKit deletes the processed file after uploading it, so the
        // export is written to a temporary directory rather than the uploads
        // directory tracked by `MediaFileManager`.
        //
        // Reuse one directory for every export rather than `MediaDirectory
        // .temporary`, which mints a new UUID per access. GutenbergKit removes
        // only the exported file, never its enclosing directories, so a fresh
        // UUID each time would leave an empty `tmp/<uuid>/Media/` behind for
        // every upload.
        exporter.mediaDirectoryType = .temporary(id: Self.exportDirectoryID)

        var imageOptions = MediaImageExporter.Options()
        imageOptions.maximumImageSize = maximumImageSize(from: settings)
        imageOptions.stripsGeoLocationIfNeeded = settings.removeLocationSetting
        imageOptions.imageCompressionQuality = settings.imageQualityForUpload.doubleValue
        if let type = url.typeIdentifier.flatMap(UTType.init), !Self.webSafeImageTypes.contains(type) {
            imageOptions.exportImageType = UTType.jpeg.identifier
        }
        exporter.imageOptions = imageOptions

        var videoOptions = MediaVideoExporter.Options()
        videoOptions.stripsGeoLocationIfNeeded = settings.removeLocationSetting
        videoOptions.exportPreset = settings.maxVideoSizeSetting.videoPreset
        videoOptions.durationLimit = videoDurationLimit
        exporter.videoOptions = videoOptions

        var urlOptions = MediaURLExporter.Options()
        urlOptions.allowableFileExtensions = allowableFileExtensions
        urlOptions.stripsGeoLocationIfNeeded = settings.removeLocationSetting
        exporter.urlOptions = urlOptions

        return exporter
    }

    private func maximumImageSize(from settings: MediaSettings) -> CGFloat? {
        let maxUploadSize = settings.imageSizeForUpload
        return maxUploadSize < Int.max ? CGFloat(maxUploadSize) : nil
    }
}
