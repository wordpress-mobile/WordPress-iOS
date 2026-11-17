import AVFoundation
import Foundation
import GutenbergKit
import os
import UniformTypeIdentifiers
import WordPressData
import WordPressMediaLibrary
import WordPressShared

/// Applies the app's Media settings (image optimization, max upload size, image
/// quality, video resolution, and location stripping) to media uploaded from
/// the GutenbergKit editor.
///
/// GutenbergKit calls `processFile` off the main actor for every upload, after
/// staging the file to disk, and holds the processor for the editor's lifetime.
/// It must not hold the editor back, so it carries only `Sendable` values.
///
/// It doesn't apply `Blog.videoDurationLimit`. The free WordPress.com sites
/// that limit targets can't upload videos through `wp/v2/media` at all.
struct GBKMediaUploadProcessor: MediaProcessor {
    /// Read on every upload, so changes made while an editor is open apply to
    /// the next upload.
    private let makeMediaSettings: @Sendable () -> MediaSettings

    /// Where each export is staged, in a directory of its own. GutenbergKit
    /// deletes the export once its upload ends, and the system purges the
    /// empty directory it leaves.
    private let stagingDirectory: URL

    /// Each materializer owns a `URLSession`, which lives until it's
    /// invalidated, so editors share one until the settings it applies change.
    private static let materializerCache = OSAllocatedUnfairLock<
        (key: MaterializerKey, materializer: UploadSourceMaterializer)?
    >(initialState: nil)

    /// Raster image types the WordPress REST API reliably accepts. The
    /// materializer converts other image formats (e.g. HEIC) to JPEG.
    private static let webSafeImageTypes: Set<UTType> = [.png, .jpeg]

    init(
        makeMediaSettings: @escaping @Sendable () -> MediaSettings = { MediaSettings() },
        stagingDirectory: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("GBKMediaUploadProcessor", isDirectory: true)
    ) {
        self.makeMediaSettings = makeMediaSettings
        self.stagingDirectory = stagingDirectory
    }

    // MARK: - MediaProcessor

    func processFile(at url: URL, mimeType: String, filename: String) async throws -> ProcessedProxyFile {
        // Only images and videos have settings to apply. The server decides
        // whether to accept anything else (e.g. archives and fonts).
        guard let sourceType = Self.sourceType(of: url, reportedMIMEType: mimeType),
            Self.isProcessable(sourceType)
        else {
            return .original
        }
        let settings = makeMediaSettings()

        // Nothing would change (no downscaling, location stripping, or
        // conversion), so skip copying the file.
        if Self.webSafeImageTypes.contains(sourceType),
            !settings.imageOptimizationEnabled,
            !settings.removeLocationSetting
        {
            return .original
        }

        try Task.checkCancellation()

        let materializer = materializer(for: UploadSettings(settings))
        let export = try await withTaskExecutorPreference(Self.exportExecutor) {
            // Cancelled while queued behind other exports.
            try Task.checkCancellation()
            return try await materializer.materialize(fileAt: url, contentType: sourceType)
        }

        guard let exportMIMEType = UTType(filenameExtension: export.pathExtension)?.preferredMIMEType else {
            // GutenbergKit only deletes exports it receives.
            try? FileManager.default.removeItem(at: export.deletingLastPathComponent())
            throw ProcessingError.unknownExportType
        }
        return .processed(
            export,
            mimeType: exportMIMEType,
            filename: Self.uploadFilename(original: filename, exportURL: export)
        )
    }

    // MARK: - Export

    private func materializer(for settings: UploadSettings) -> UploadSourceMaterializer {
        let key = MaterializerKey(settings: settings, stagingDirectory: stagingDirectory)
        return Self.materializerCache.withLock { cache in
            if let cache, cache.key == key {
                return cache.materializer
            }
            let materializer = UploadSourceMaterializer(policy: settings.policy, stagingDirectory: stagingDirectory)
            cache = (key, materializer)
            return materializer
        }
    }

    /// Starts exports one at a time, as `MediaImportService` does. Image work
    /// is synchronous, so this keeps it off the Swift concurrency pool and
    /// limits peak memory to one decode.
    private static let exportExecutor = SerialQueueExecutor(label: "org.wordpress.gbk-media-upload-processor")

    private enum ProcessingError: Error {
        case unknownExportType
    }

    // MARK: - Output naming

    /// The name WordPress turns into the attachment's slug and title: the
    /// editor's, with the export's extension because a conversion changes it.
    private static func uploadFilename(original: String, exportURL: URL) -> String {
        let originalBase = ((original as NSString).lastPathComponent as NSString).deletingPathExtension
        let base = originalBase.nonEmptyString() ?? exportURL.deletingPathExtension().lastPathComponent
        guard let exportExtension = exportURL.pathExtension.nonEmptyString() else {
            return base
        }
        // `.jpg`, as `MediaService` uploads, because some image plugins expect
        // it (WordPress-iOS#4663).
        let fileExtension = exportExtension.lowercased() == "jpeg" ? "jpg" : exportExtension
        return "\(base).\(fileExtension)"
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

    /// Whether the type is an image or video the materializer can apply
    /// settings to. GIF and SVG pass through, since re-encoding would flatten
    /// an animation or rasterize vectors.
    private static func isProcessable(_ type: UTType) -> Bool {
        if type == .gif || type == .svg {
            return false
        }
        if type.conforms(to: .movie) {
            // AVFoundation can't read every container that conforms to
            // `.movie` (e.g. WebM, WMV), and the export would fail an upload
            // WordPress accepts.
            return isExportableVideoType(type)
        }
        return type.conforms(to: .image)
    }

    /// Whether AVFoundation can open the container at all. Matched by
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
}

private struct MaterializerKey: Equatable {
    let settings: UploadSettings
    let stagingDirectory: URL
}

/// The Media settings an upload policy is built from, mirroring the option
/// mapping in `MediaImportService`.
private struct UploadSettings: Equatable {
    let imageMaxDimension: Int?
    let imageQuality: Double
    let videoPreset: String
    let removesLocation: Bool

    init(_ settings: MediaSettings) {
        let maxUploadSize = settings.imageSizeForUpload
        imageMaxDimension = maxUploadSize < Int.max ? maxUploadSize : nil
        imageQuality = settings.imageQualityForUpload.doubleValue
        videoPreset = settings.maxVideoSizeSetting.videoPreset
        removesLocation = settings.removeLocationSetting
    }

    var policy: MediaUploadPolicy {
        MediaUploadPolicy(
            // The editor picks its own files.
            filePickerContentTypes: [],
            // Not checked against `Blog.allowedFileTypes`: the editor already
            // validated the type, and that cached option can lag the server,
            // so it could only refuse a file the server would accept.
            isAllowedForUpload: { _, _ in true },
            imageMaxDimension: imageMaxDimension,
            imageJpegQuality: imageQuality,
            // Mirrors `ItemProviderMediaExporter`, which converts every image
            // type but PNG and JPEG.
            convertHEICToJPEG: true,
            videoMaxDurationSeconds: nil,
            videoExportPreset: videoPreset,
            videoOutputContentType: .mpeg4Movie,
            stripGPSLocation: removesLocation
        )
    }
}

/// Runs the nonisolated async work of tasks that prefer it on a serial
/// dispatch queue. Synchronous stretches run one at a time, while a video
/// export that suspends lets the next export start, as in the legacy editor.
private final class SerialQueueExecutor: TaskExecutor {
    private let queue: DispatchQueue

    init(label: String) {
        queue = DispatchQueue(label: label, autoreleaseFrequency: .workItem)
    }

    func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        queue.async {
            job.runSynchronously(on: self.asUnownedTaskExecutor())
        }
    }
}
