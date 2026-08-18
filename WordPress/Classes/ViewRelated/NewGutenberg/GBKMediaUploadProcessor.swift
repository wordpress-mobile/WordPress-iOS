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

    /// The temporary directory an export is written to.
    ///
    /// GutenbergKit deletes the processed file after uploading it, so exports
    /// go to a temporary directory rather than the uploads directory tracked by
    /// `MediaFileManager`.
    ///
    /// Every export gets its own directory. Destination names come from
    /// `URL.incrementalFilename()`, a check-then-act `fileExists` loop with no
    /// locking, and uploads are processed concurrently — one task per
    /// connection — so sharing a directory lets two exports of the same source
    /// name resolve to the same path and clobber each other. A per-export
    /// directory removes the shared state instead of racing on it.
    private let makeExportDirectory: @Sendable () -> MediaDirectory

    /// Raster image types the WordPress REST API reliably accepts. Other image
    /// formats (e.g. HEIC) are converted to JPEG during processing, mirroring
    /// `ItemProviderMediaExporter`.
    ///
    /// - Note: SVG is deliberately absent. It is web-safe, but it is a vector
    ///   format that ImageIO cannot decode or encode, so it never reaches the
    ///   exporter — `processFile` returns it unchanged (see below).
    private static let webSafeImageTypes: Set<UTType> = [.png, .jpeg, .gif]

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
        makeMediaSettings: @escaping @Sendable () -> MediaSettings = { MediaSettings() },
        makeExportDirectory: @escaping @Sendable () -> MediaDirectory = { .temporary(id: UUID()) }
    ) {
        self.videoDurationLimit = videoDurationLimit
        self.allowableFileExtensions = allowableFileExtensions
        self.makeMediaSettings = makeMediaSettings
        self.makeExportDirectory = makeExportDirectory
    }

    // MARK: - MediaUploadDelegate

    func processFile(at url: URL, mimeType: String, filename: String) async throws -> ProcessedProxyFile {
        let sourceType = Self.sourceType(of: url, reportedMIMEType: mimeType)
        let expected = try Self.expectedExport(of: url, type: sourceType)
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
            // SVG conforms to `UTType.image`, so it lands here, but ImageIO
            // cannot decode or encode it: the export would fail rather than
            // produce a file. Upload it unchanged, like a GIF.
            if sourceType == .svg {
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
                let sourceType,
                Self.webSafeImageTypes.contains(sourceType)
            {
                return .original
            }
        case .video:
            // Always process video to apply the export preset, duration
            // limit, and location stripping.
            break
        }

        let exportImageType = Self.exportImageType(for: expected, sourceType: sourceType)
        let directory = makeExportDirectory()

        do {
            let export = try await makeExporter(
                for: url,
                expected: expected,
                settings: settings,
                exportImageType: exportImageType,
                directory: directory
            )
            .export()

            let mimeType = try Self.mimeType(of: export.url, exportImageType: exportImageType)
            return .processed(export.url, mimeType: mimeType, filename: export.url.lastPathComponent)
        } catch {
            // Nothing else sweeps this directory: GutenbergKit removes only the
            // file it is handed, and `MediaFileManager`'s cleanup covers the
            // uploads directory alone. On the success path the directory is
            // left holding the file GutenbergKit is about to upload, but a
            // failure here would otherwise abandon a full-size export — and any
            // directory the export already created — for the lifetime of the
            // app's container.
            try? FileManager.default.removeItem(at: directory.url)
            throw error
        }
    }

    // MARK: - Exporter configuration

    /// Builds an exporter configured from the app's Media settings, mirroring
    /// the option mapping in `MediaImportService`.
    ///
    /// Returns the concrete exporter for the branch rather than
    /// `MediaURLExporter`, which re-derives the type from the path extension in
    /// `exportURL` and so would reject a file classified via its reported MIME
    /// type. `MediaImageExporter` reads the type from the file's contents with
    /// `CGImageSourceGetType`, so it handles an extensionless image correctly.
    private func makeExporter(
        for url: URL,
        expected: MediaURLExporter.URLExportExpectation,
        settings: MediaSettings,
        exportImageType: UTType?,
        directory: MediaDirectory
    ) -> any MediaExporter {
        switch expected {
        case .video:
            let exporter = MediaVideoExporter(url: url)
            exporter.mediaDirectoryType = directory
            var options = MediaVideoExporter.Options()
            options.stripsGeoLocationIfNeeded = settings.removeLocationSetting
            options.exportPreset = settings.maxVideoSizeSetting.videoPreset
            options.durationLimit = videoDurationLimit
            exporter.options = options
            return exporter
        case .image, .gif, .other:
            // Only images reach the exporter: `.gif` and `.other` return
            // `.original` before this point.
            let exporter = MediaImageExporter(url: url)
            exporter.mediaDirectoryType = directory
            var options = MediaImageExporter.Options()
            options.maximumImageSize = maximumImageSize(from: settings)
            options.stripsGeoLocationIfNeeded = settings.removeLocationSetting
            options.imageCompressionQuality = settings.imageQualityForUpload.doubleValue
            // `exportImageType` is the destination type `MediaImageExporter`
            // writes, and it also determines the output file extension. Left
            // nil, the source type is kept.
            options.exportImageType = exportImageType?.identifier
            exporter.options = options
            return exporter
        }
    }

    private func maximumImageSize(from settings: MediaSettings) -> CGFloat? {
        let maxUploadSize = settings.imageSizeForUpload
        return maxUploadSize < Int.max ? CGFloat(maxUploadSize) : nil
    }

    // MARK: - Type resolution

    /// The type of the file to process.
    ///
    /// Resolved from the file itself, falling back to the type the editor
    /// reported. The URL resolves its type from the path extension alone, and
    /// an upload can arrive without one — GutenbergKit names the temp file
    /// after the multipart `filename`, which the editor does not guarantee
    /// carries an extension (its native inserter derives one from a URL path
    /// segment). Such a file resolves to the generic `public.data`, which
    /// conforms to no media type, so the export would be rejected outright.
    private static func sourceType(of url: URL, reportedMIMEType: String) -> UTType? {
        guard let type = url.typeIdentifier.flatMap(UTType.init), type != .data else {
            return UTType(mimeType: reportedMIMEType)
        }
        return type
    }

    /// Classifies a file the way `MediaURLExporter.expectedExport(with:)` does,
    /// but from an already-resolved type so the caller can supply one the URL
    /// alone cannot provide.
    private static func expectedExport(
        of url: URL,
        type: UTType?
    ) throws -> MediaURLExporter.URLExportExpectation {
        guard url.isFileURL else {
            throw MediaURLExporter.URLExportError.invalidFileURL
        }
        guard let type else {
            throw MediaURLExporter.URLExportError.unknownFileUTI
        }
        if type == .gif {
            return .gif
        } else if type.conforms(to: .video) || type.conforms(to: .movie) {
            return .video
        } else if type.conforms(to: .image) {
            return .image
        } else if type.conforms(to: .content) || type.conforms(to: .zip) {
            return .other
        }
        throw MediaURLExporter.URLExportError.unsupportedFileType
    }

    /// The type `MediaImageExporter` should write, or `nil` to keep the source
    /// type. Only image exports convert: everything the REST API accepts as-is
    /// is left alone, and the rest becomes JPEG.
    private static func exportImageType(
        for expected: MediaURLExporter.URLExportExpectation,
        sourceType: UTType?
    ) -> UTType? {
        guard case .image = expected, let sourceType else {
            return nil
        }
        return webSafeImageTypes.contains(sourceType) ? nil : .jpeg
    }

    /// The MIME type of a finished export.
    ///
    /// An image export writes `exportImageType` when set, so that value is
    /// authoritative and needs no round-trip through the output path. Only the
    /// cases that keep the source type — every video, and a web-safe image —
    /// fall back to reading the file back.
    private static func mimeType(of url: URL, exportImageType: UTType?) throws -> String {
        let type = exportImageType ?? url.typeIdentifier.flatMap(UTType.init)
        guard let mimeType = type?.preferredMIMEType else {
            throw MediaURLExporter.URLExportError.unknownFileUTI
        }
        return mimeType
    }
}
