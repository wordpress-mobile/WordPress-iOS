import AVFoundation
import Foundation
import GutenbergKit
import os
import UniformTypeIdentifiers
import WordPressData
import WordPressShared

/// Applies the app's Media settings (image optimization, max upload size, image
/// quality, video resolution, and location stripping) to media uploaded from
/// the GutenbergKit editor.
///
/// GutenbergKit calls `processFile` off the main actor for every upload, after
/// staging the file to disk, and holds the processor for the editor's lifetime.
/// It must not hold the editor back, so it carries only `Sendable` values.
struct GBKMediaUploadProcessor: MediaProcessor {
    private let videoDurationLimit: TimeInterval?

    /// Read on every upload, so changes made while an editor is open apply to
    /// the next upload.
    private let makeMediaSettings: @Sendable () -> MediaSettings

    /// Identifies the temporary directory exports are written to. GutenbergKit
    /// deletes each export once its upload ends, so one directory is reused.
    private let exportDirectoryID: UUID

    /// Where each upload's source is cloned under a unique name before export.
    private let sourceDirectory: URL

    private static let defaultExportDirectoryID = UUID(uuidString: "1D8A4E5C-1F3B-4E7A-9C2D-6B0F8A5E3C71")!

    /// Raster image types the WordPress REST API reliably accepts. Other image
    /// formats (e.g. HEIC) are converted to JPEG, mirroring
    /// `ItemProviderMediaExporter`. GIF and SVG return `.original` before this
    /// is read.
    private static let webSafeImageTypes: Set<UTType> = [.png, .jpeg]

    @MainActor
    init(blog: Blog) {
        self.init(videoDurationLimit: blog.videoDurationLimit)
    }

    init(
        videoDurationLimit: TimeInterval?,
        makeMediaSettings: @escaping @Sendable () -> MediaSettings = { MediaSettings() },
        exportDirectoryID: UUID = GBKMediaUploadProcessor.defaultExportDirectoryID,
        sourceDirectory: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("GBKMediaUploadProcessor-sources", isDirectory: true)
    ) {
        self.videoDurationLimit = videoDurationLimit
        self.makeMediaSettings = makeMediaSettings
        self.exportDirectoryID = exportDirectoryID
        self.sourceDirectory = sourceDirectory
    }

    // MARK: - MediaProcessor

    func processFile(at url: URL, mimeType: String, filename: String) async throws -> ProcessedProxyFile {
        let sourceType = Self.sourceType(of: url, reportedMIMEType: mimeType)
        let expected: MediaURLExporter.URLExportExpectation
        do {
            expected = try MediaURLExporter.expectedExport(with: url, type: sourceType)
        } catch MediaURLExporter.URLExportError.unknownFileUTI, MediaURLExporter.URLExportError.unsupportedFileType {
            // Only images and videos have settings to apply. The server decides
            // whether to accept anything else (e.g. archives and fonts).
            return .original
        }
        let settings = makeMediaSettings()

        switch expected {
        case .gif:
            return .original
        case .other:
            // Not re-checked against `Blog.allowedFileTypes`: the editor already
            // validated the type, and that cached option can lag the server, so
            // it could only refuse a file the server would accept.
            return .original
        case .image:
            // SVG conforms to `UTType.image`, but ImageIO can't decode it.
            if sourceType == .svg {
                return .original
            }
            // Nothing would change: no downscaling, location stripping, or
            // conversion. Skipping the export also skips the exporter's EXIF
            // orientation normalization, which WordPress 5.3+ performs on the
            // server anyway (WordPress-iOS#12703, core changeset 46202).
            if !settings.imageOptimizationEnabled,
                !settings.removeLocationSetting,
                let sourceType,
                Self.webSafeImageTypes.contains(sourceType)
            {
                return .original
            }
        case .video:
            // AVFoundation can't read every container that conforms to `.movie`
            // (e.g. WebM, WMV), and `MediaVideoExporter` rejects those rather
            // than passing them along.
            if let sourceType, !Self.isExportableVideoType(sourceType) {
                return .original
            }
        }

        try Task.checkCancellation()

        let source = try cloneSource(at: url, type: sourceType)
        defer { try? FileManager.default.removeItem(at: source) }

        let exportImageType = Self.exportImageType(for: expected, sourceType: sourceType)
        let exporter = makeExporter(
            for: source,
            expected: expected,
            settings: settings,
            exportImageType: exportImageType
        )
        let export = try await Self.run(exporter)

        let exportMIMEType: String
        do {
            exportMIMEType = try Self.mimeType(of: export.url, exportImageType: exportImageType)
        } catch {
            // GutenbergKit only deletes exports it receives.
            try? FileManager.default.removeItem(at: export.url)
            throw error
        }
        return .processed(
            export.url,
            mimeType: exportMIMEType,
            filename: Self.uploadFilename(original: filename, exportURL: export.url)
        )
    }

    // MARK: - Export

    /// Clones the staged upload to a unique name for the exporters to read.
    ///
    /// The exporters name their output after the source file, and pick a free
    /// name with an unlocked check-then-act loop. GutenbergKit stages uploads
    /// under the editor's filename, so two concurrent uploads of `IMG_0001.HEIC`
    /// would otherwise race for one output name. The clone also gets an
    /// extension from the resolved type, which `AVURLAsset` needs. On APFS the
    /// copy is a clone, so it costs no disk space.
    private func cloneSource(at url: URL, type: UTType?) throws -> URL {
        try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
        var clone = sourceDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        if let fileExtension = type?.preferredFilenameExtension ?? url.pathExtension.nonEmptyString() {
            clone.appendPathExtension(fileExtension)
        }
        try FileManager.default.copyItem(at: url, to: clone)
        return clone
    }

    /// Builds an exporter configured from the app's Media settings, mirroring
    /// the option mapping in `MediaImportService`.
    ///
    /// Uses the concrete exporters rather than `MediaURLExporter`, which
    /// re-derives the type from the path extension and would reject a file
    /// classified from its reported MIME type.
    private func makeExporter(
        for url: URL,
        expected: MediaURLExporter.URLExportExpectation,
        settings: MediaSettings,
        exportImageType: UTType?
    ) -> any MediaExporter {
        switch expected {
        case .video:
            let exporter = MediaVideoExporter(url: url)
            exporter.mediaDirectoryType = .temporary(id: exportDirectoryID)
            var options = MediaVideoExporter.Options()
            options.stripsGeoLocationIfNeeded = settings.removeLocationSetting
            options.exportPreset = settings.maxVideoSizeSetting.videoPreset
            options.durationLimit = videoDurationLimit
            exporter.options = options
            return exporter
        case .image, .gif, .other:
            // Only images get here: `.gif` and `.other` return `.original` first.
            let exporter = MediaImageExporter(url: url)
            exporter.mediaDirectoryType = .temporary(id: exportDirectoryID)
            var options = MediaImageExporter.Options()
            let maxUploadSize = settings.imageSizeForUpload
            options.maximumImageSize = maxUploadSize < Int.max ? CGFloat(maxUploadSize) : nil
            options.stripsGeoLocationIfNeeded = settings.removeLocationSetting
            options.imageCompressionQuality = settings.imageQualityForUpload.doubleValue
            // Also sets the output extension. Nil keeps the source type.
            options.exportImageType = exportImageType?.identifier
            exporter.options = options
            return exporter
        }
    }

    /// Starts exports one at a time, as `MediaImportService` does.
    /// `MediaImageExporter` works synchronously, so this keeps image work off
    /// the Swift concurrency pool and limits peak memory to one decode.
    private static let exportQueue = DispatchQueue(
        label: "org.wordpress.gbk-media-upload-processor",
        autoreleaseFrequency: .workItem
    )

    /// Runs an export on `exportQueue`, cancelling it if the task is cancelled.
    ///
    /// GutenbergKit cancels the task when the editor goes away or the page
    /// abandons the upload, and `MediaExporter.export()` doesn't observe that.
    private static func run(_ exporter: any MediaExporter) async throws -> MediaExport {
        let progress = OSAllocatedUnfairLock<Progress?>(initialState: nil)
        let isCancelled = OSAllocatedUnfairLock(initialState: false)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                exportQueue.async {
                    // Cancelled while queued behind other exports.
                    guard !isCancelled.withLock({ $0 }) else {
                        continuation.resume(throwing: CancellationError())
                        return
                    }
                    let started = exporter.export(
                        onCompletion: { continuation.resume(returning: $0) },
                        onError: { continuation.resume(throwing: $0) }
                    )
                    progress.withLock { $0 = started }
                    // Cancelled while the export was starting, so `onCancel`
                    // had nothing to cancel.
                    if isCancelled.withLock({ $0 }) {
                        started.cancel()
                    }
                }
            }
        } onCancel: {
            isCancelled.withLock { $0 = true }
            progress.withLock { $0 }?.cancel()
        }
    }

    // MARK: - Output naming

    /// The name WordPress turns into the attachment's slug and title: the
    /// editor's, with the export's extension because a conversion changes it.
    private static func uploadFilename(original: String, exportURL: URL) -> String {
        let base = ((original as NSString).lastPathComponent as NSString).deletingPathExtension
        guard !base.isEmpty else {
            return exportURL.lastPathComponent
        }
        guard let exportExtension = exportURL.pathExtension.nonEmptyString() else {
            return base
        }
        return "\(base).\(exportExtension)"
    }

    // MARK: - Type resolution

    /// The type of the file to process: from its extension, or the reported
    /// MIME type when the extension says nothing.
    ///
    /// The editor doesn't guarantee a filename has an extension, and one no
    /// UTI declares (e.g. `.jfif`) resolves to a dynamic type that conforms to
    /// nothing. Either would fail an upload the MIME type describes correctly.
    private static func sourceType(of url: URL, reportedMIMEType: String) -> UTType? {
        guard let type = url.typeIdentifier.flatMap(UTType.init), !isUninformative(type) else {
            return type(ofMIMEType: reportedMIMEType)
        }
        return type
    }

    private static func isUninformative(_ type: UTType) -> Bool {
        type == .data || type.isDynamic
    }

    /// Whether `MediaVideoExporter` can open the container at all. Matched by
    /// conformance, since a subtype (e.g. DRM-wrapped MPEG-4) may not be listed.
    private static func isExportableVideoType(_ type: UTType) -> Bool {
        exportableVideoTypes.contains { type.conforms(to: $0) }
    }

    private static let exportableVideoTypes: Set<UTType> = Set(
        AVURLAsset.audiovisualTypes().compactMap { UTType($0.rawValue) }
    )

    /// The type a reported MIME type names, ignoring parameters and casing
    /// (RFC 9110 §8.3), or `nil` for `application/octet-stream`, which the
    /// editor sends when the browser doesn't know the type.
    private static func type(ofMIMEType mimeType: String) -> UTType? {
        let normalized = mimeType.prefix(while: { $0 != ";" })
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
        guard !normalized.isEmpty, normalized != "application/octet-stream" else {
            return nil
        }
        return UTType(mimeType: normalized)
    }

    /// The type `MediaImageExporter` should write, or `nil` to keep the
    /// source type.
    private static func exportImageType(
        for expected: MediaURLExporter.URLExportExpectation,
        sourceType: UTType?
    ) -> UTType? {
        guard case .image = expected, let sourceType else {
            return nil
        }
        return webSafeImageTypes.contains(sourceType) ? nil : .jpeg
    }

    private static func mimeType(of url: URL, exportImageType: UTType?) throws -> String {
        let type = exportImageType ?? url.typeIdentifier.flatMap(UTType.init)
        guard let mimeType = type?.preferredMIMEType else {
            throw MediaURLExporter.URLExportError.unknownFileUTI
        }
        return mimeType
    }
}
