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
/// and snapshots the `Blog`-derived value it needs at initialization.
final class GBKMediaUploadProcessor: MediaUploadDelegate, Sendable {
    private let videoDurationLimit: TimeInterval?
    private let makeMediaSettings: @Sendable () -> MediaSettings

    /// The temporary directory exports are written to.
    ///
    /// One directory, reused: GutenbergKit deletes the file it was handed on
    /// both the success and the failure path, so nothing here needs cleanup. A
    /// fresh directory per export would, since nothing sweeps those.
    ///
    /// Sharing it is safe despite `incrementalFilename()`'s unlocked
    /// check-then-act loop: GutenbergKit writes each upload to
    /// `<uuid>-<filename>` and the exporters name their output after it, so
    /// concurrent exports cannot resolve to the same name.
    private let makeExportDirectory: @Sendable () -> MediaDirectory

    private static let exportDirectoryID = UUID(uuidString: "1D8A4E5C-1F3B-4E7A-9C2D-6B0F8A5E3C71")!

    /// Raster image types the WordPress REST API reliably accepts. Other image
    /// formats (e.g. HEIC) are converted to JPEG during processing, mirroring
    /// `ItemProviderMediaExporter`.
    ///
    /// Only consulted for an `.image` export, so it lists just the types that
    /// reach that branch. GIF and SVG are web-safe too but are absent: both
    /// return `.original` before any of this is read — GIF from its own
    /// `expectedExport` case, SVG because ImageIO can neither decode nor encode
    /// it.
    private static let webSafeImageTypes: Set<UTType> = [.png, .jpeg]

    @MainActor
    convenience init(blog: Blog) {
        self.init(videoDurationLimit: blog.videoDurationLimit)
    }

    init(
        videoDurationLimit: TimeInterval?,
        makeMediaSettings: @escaping @Sendable () -> MediaSettings = { MediaSettings() },
        makeExportDirectory: @escaping @Sendable () -> MediaDirectory = {
            .temporary(id: GBKMediaUploadProcessor.exportDirectoryID)
        }
    ) {
        self.videoDurationLimit = videoDurationLimit
        self.makeMediaSettings = makeMediaSettings
        self.makeExportDirectory = makeExportDirectory
    }

    // MARK: - MediaUploadDelegate

    /// Whether the file is worth materializing for `processFile`.
    ///
    /// GutenbergKit calls this from the multipart headers alone, before
    /// streaming the upload to a temp file. Returning `false` skips that copy
    /// and forwards the original request body to WordPress unchanged, so it is
    /// only correct where `processFile` would return `.original` for *any*
    /// Media settings — the metadata here cannot answer anything finer.
    ///
    /// This is a fast path, never a second place the policy lives: every `false`
    /// below mirrors a branch of `processFile` that ignores `settings`.
    /// Declining is also unrecoverable — the file is never seen again — so
    /// anything undecidable from metadata claims the file and decides for real
    /// once the bytes are on disk.
    func handlesFile(ofType mimeType: String, named filename: String) -> Bool {
        // The file doesn't exist yet, so stand in for it with the filename
        // extension and resolve in the same order `sourceType(of:)` does: the
        // file's own type first, the reported one only as a fallback. Reversing
        // the two here would let a mislabeled `Content-Type` decline a file
        // `processFile` would have classified — and processed — from its
        // extension. Both signals are untrustworthy in ways `processFile` can
        // recover from and this cannot, hence the bias toward `true`.
        guard let type = Self.type(ofExtensionIn: filename) ?? Self.type(ofMIMEType: mimeType) else {
            return true
        }
        guard let expected = try? Self.expectedExport(of: nil, type: type) else {
            return true
        }
        switch expected {
        case .gif, .other:
            // Always returned unchanged, whatever the settings: only images and
            // videos are processed.
            return false
        case .image:
            // SVG conforms to `UTType.image` but is returned unchanged for any
            // settings, because ImageIO cannot decode it (see `processFile`).
            // Declining it skips a temp-file copy that could never be used.
            //
            // Every other image may be downscaled, stripped, or converted
            // depending on settings and on the file's contents, so decide in
            // `processFile`.
            return type != .svg
        case .video:
            // Always exported, to apply the preset and duration limit.
            return true
        }
    }

    func processFile(at url: URL, mimeType: String, filename: String) async throws -> ProcessedProxyFile {
        let sourceType = Self.sourceType(of: url, reportedMIMEType: mimeType)
        let expected = try Self.expectedExport(of: url, type: sourceType)
        let settings = makeMediaSettings()

        switch expected {
        case .gif:
            // GIFs are uploaded unchanged; processing would only copy the file.
            return .original
        case .other:
            // Non-media files are uploaded unchanged.
            //
            // Deliberately narrower than `MediaURLExporter.exportURL`, which
            // also rejects extensions outside the site's allowed list. That
            // check belongs to the legacy picker, which hands over arbitrary
            // files with nothing having vetted them. Here the editor has already
            // validated the file against the site's real `allowedMimeTypes` from
            // `/wp-block-editor/v1/settings` before the upload reaches us, so
            // re-checking against `Blog.allowedFileTypes` — a cached option that
            // can lag the server — could only ever reject a file the server
            // would have accepted.
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
            //
            // Skipping the export also skips the exporter's unconditional EXIF
            // orientation normalization, so a sideways-shot photo uploads with
            // its orientation flag intact rather than rotated into its pixels.
            // That is deliberate: the normalization predates WordPress 5.3,
            // whose `wp_create_image_subsizes` rotates on the server for every
            // site, self-hosted included. Re-encoding here to bake in a
            // rotation the server performs anyway would cost a lossy pass on a
            // photo the user asked not to optimize.
            //
            // See WordPress-iOS#12703 and core changeset 46202.
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
        let export = try await makeExporter(
            for: url,
            expected: expected,
            settings: settings,
            exportImageType: exportImageType,
            directory: makeExportDirectory()
        )
        .export()

        let mimeType = try Self.mimeType(of: export.url, exportImageType: exportImageType)
        return .processed(
            export.url,
            mimeType: mimeType,
            filename: Self.uploadFilename(original: filename, exportURL: export.url)
        )
    }

    // MARK: - Output naming

    /// The name the processed file is uploaded under, which WordPress turns
    /// into the attachment's slug and title.
    ///
    /// The editor's name, with the extension from the export because a
    /// conversion changes it. The export's own name carries the UUID prefix
    /// GutenbergKit gave the temp file, so it can't be used.
    private static func uploadFilename(original: String, exportURL: URL) -> String {
        let name = (original as NSString).lastPathComponent
        let base = (name as NSString).deletingPathExtension
        guard !base.isEmpty else {
            return exportURL.lastPathComponent
        }
        let exportExtension = exportURL.pathExtension
        guard !exportExtension.isEmpty else {
            return base
        }
        return "\(base).\(exportExtension)"
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
    /// two kinds of upload defeat that:
    ///
    /// - No extension at all. GutenbergKit names the temp file after the
    ///   multipart `filename`, which the editor does not guarantee carries an
    ///   extension (its native inserter derives one from a URL path segment).
    ///   Such a file resolves to the generic `public.data`.
    /// - An extension no UTI declares. `photo.jfif` is a plain JPEG WordPress
    ///   accepts, but nothing claims `jfif`, so it resolves to a *dynamic* type
    ///   synthesized from the extension (`dyn.ah62d4rv4ge80y3xmq2`).
    ///
    /// Neither conforms to any media type, so `expectedExport` would throw and
    /// fail an upload that the reported `Content-Type` describes perfectly.
    /// Both therefore defer to it — for `photo.jfif`, `image/jpeg`.
    private static func sourceType(of url: URL, reportedMIMEType: String) -> UTType? {
        guard let type = url.typeIdentifier.flatMap(UTType.init), !isUninformative(type) else {
            return type(ofMIMEType: reportedMIMEType)
        }
        return type
    }

    /// Whether a type says nothing about the file's format and should give way
    /// to the reported MIME type. See `sourceType(of:reportedMIMEType:)`.
    private static func isUninformative(_ type: UTType) -> Bool {
        type == .data || type.isDynamic
    }


    /// The type a reported MIME type names, or `nil` when it names nothing
    /// usable.
    ///
    /// `UTType(mimeType:)` matches the bare `type/subtype` only, so the header
    /// is normalized first. Two shapes reach us that it would otherwise miss:
    ///
    /// - Parameters and casing: `Content-Type` may carry parameters
    ///   (`image/jpeg; charset=binary`) and its casing is not significant
    ///   (RFC 9110 §8.3). Left as-is, both resolve to a dynamic UTType that
    ///   conforms to nothing.
    /// - Placeholders: GutenbergKit's multipart parser defaults a part with no
    ///   `Content-Type` to `text/plain` (RFC 7578 §4.4), and it picks the file
    ///   part by the presence of a `filename` parameter rather than by content
    ///   type — so a real image can arrive labeled `text/plain`. Treating that
    ///   as authoritative would classify a photo as a document.
    private static func type(ofMIMEType mimeType: String) -> UTType? {
        let normalized = mimeType.prefix(while: { $0 != ";" })
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
        guard !normalized.isEmpty, !placeholderMIMETypes.contains(normalized) else {
            return nil
        }
        return UTType(mimeType: normalized)
    }

    /// MIME types that carry no information about the file. `octet-stream` is
    /// the generic "unknown bytes" type; `text/plain` is what GutenbergKit's
    /// multipart parser substitutes for a part that sent no `Content-Type`.
    private static let placeholderMIMETypes: Set<String> = [
        "application/octet-stream", "text/plain"
    ]

    /// The type a filename's extension names, for use before the file exists.
    /// `processFile` reads the type off the file itself instead.
    ///
    /// Discards a dynamic type for the same reason `sourceType` does, and to
    /// stay in step with it: an extension no UTI declares must fall through to
    /// the reported MIME type in both places, or `handlesFile` would classify a
    /// `.jfif` from a type that conforms to nothing while `processFile`
    /// classifies the same file as the JPEG it is.
    private static func type(ofExtensionIn filename: String) -> UTType? {
        let fileExtension = (filename as NSString).pathExtension.lowercased()
        guard !fileExtension.isEmpty else {
            return nil
        }
        return UTType(filenameExtension: fileExtension).flatMap { isUninformative($0) ? nil : $0 }
    }

    /// Classifies a file the way `MediaURLExporter.expectedExport(with:)` does,
    /// but from an already-resolved type so the caller can supply one the URL
    /// alone cannot provide.
    /// - Parameter url: The file being classified, or `nil` when only the type
    ///   is known — `handlesFile` runs before the file exists.
    private static func expectedExport(
        of url: URL?,
        type: UTType?
    ) throws -> MediaURLExporter.URLExportExpectation {
        if let url, !url.isFileURL {
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
