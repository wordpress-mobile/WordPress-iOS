import AVFoundation
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers
import WordPressAPI
import os

struct MaterializedUpload: Sendable {
    let tempFileURL: URL
    let params: MediaCreateParams
    let kind: MediaKind

    /// The uploaded file's basename, shown in the Uploads UI.
    var displayName: String {
        tempFileURL.lastPathComponent
    }

    /// The per-upload directory that owns `tempFileURL`. The materializer
    /// stages every upload in its own dedicated directory so consumers can
    /// dispose of an upload's on-disk footprint by deleting this directory,
    /// without knowing the layout inside it. Delete this (never a parent of
    /// it) when the upload is finished, cancelled, or dismissed.
    var stagingDirectory: URL {
        tempFileURL.deletingLastPathComponent()
    }
}

final class UploadSourceMaterializer: Sendable {
    private let policy: MediaUploadPolicy
    private let temporaryRoot: URL
    private let filenames = UploadFilenameAllocator()
    private let remoteDownloader = RemoteDownloader()

    /// Default staging root for materialized uploads. Rooted in Application
    /// Support (not the system temp dir) so files survive app suspension and a
    /// queued Retry can reuse them; iOS purges tmp under storage pressure while
    /// the app is suspended. Excluded from backup, and swept of crash-orphaned
    /// entries at launch via `sweepOrphanedStagingFiles()`.
    static let defaultStagingDirectory: URL = {
        let base =
            (try? FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )) ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("WordPressMediaLibrary-Uploads", isDirectory: true)
    }()

    /// Reference instant for the sweep, captured the first time it runs.
    /// Deliberately not a true process-start time (it is only as early as that
    /// first call), so it must not be reused as a general launch timestamp; it
    /// exists solely to tell this run's staging dirs from an earlier run's.
    private static let sweepReferenceDate = Date()

    /// Deletes staged uploads under the default staging root that were created
    /// before this process began sweeping. In-memory uploader state never
    /// survives process termination, so any earlier entry was orphaned by a
    /// crash or force-quit in a previous run. Call this once shortly after app
    /// launch, before the first upload is staged, so the reference it captures
    /// approximates this process's start: staging dirs this run creates
    /// afterward are always newer and never swept, so a later concurrent
    /// materialization (or a parallel test sharing the default root) is safe.
    public static func sweepOrphanedStagingFiles() {
        sweepOrphanedStagingFiles(in: defaultStagingDirectory, createdBefore: sweepReferenceDate)
    }

    /// Testable core of `sweepOrphanedStagingFiles()`. Entries with an
    /// unreadable creation date are skipped, erring on the side of not
    /// deleting.
    static func sweepOrphanedStagingFiles(in root: URL, createdBefore cutoff: Date) {
        guard
            let contents = try? FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.creationDateKey]
            )
        else { return }
        for url in contents {
            guard
                let creationDate = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate,
                creationDate < cutoff
            else { continue }
            try? FileManager.default.removeItem(at: url)
        }
    }

    init(
        policy: MediaUploadPolicy,
        temporaryRoot: URL = UploadSourceMaterializer.defaultStagingDirectory
    ) {
        self.policy = policy
        self.temporaryRoot = temporaryRoot
    }

    func materialize(
        source: UploadSource,
        into stageProgress: Progress
    ) async throws -> MaterializedUpload {
        try ensureStagingRoot()
        let parentDir = temporaryRoot.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)

        do {
            let result: MaterializedUpload
            switch source {
            case .photoLibrary(let itemProvider, let suggestedName, let hint):
                result = try await materializePhotoLibrary(
                    parentDir: parentDir,
                    itemProvider: itemProvider,
                    suggestedName: suggestedName,
                    hint: hint,
                    stageProgress: stageProgress
                )
            case .cameraImage(let image, let capturedAt):
                result = try materializeCameraImage(
                    parentDir: parentDir,
                    image: image,
                    capturedAt: capturedAt
                )
            case .cameraVideo(let url, let capturedAt):
                result = try await materializeCameraVideo(
                    parentDir: parentDir,
                    sourceURL: url,
                    capturedAt: capturedAt,
                    stageProgress: stageProgress
                )
            case .file(let url):
                result = try await materializeFile(
                    parentDir: parentDir,
                    sourceURL: url,
                    stageProgress: stageProgress
                )
            case .remoteURL(let remote):
                result = try await materializeRemoteURL(
                    parentDir: parentDir,
                    remote: remote,
                    stageProgress: stageProgress
                )
            case .imagePlayground(let url, let suggestedName):
                result = try materializeImagePlayground(
                    parentDir: parentDir,
                    sourceURL: url,
                    suggestedName: suggestedName
                )
            }
            // Ensure the stage child reaches its total even when sub-methods
            // didn't report fine-grained progress (image sub-methods snap
            // 0→100 here; video sub-methods set it themselves after polling).
            stageProgress.completedUnitCount = stageProgress.totalUnitCount
            return result
        } catch {
            try? FileManager.default.removeItem(at: parentDir)
            throw error
        }
    }

    // MARK: - Photo Library

    private func materializePhotoLibrary(
        parentDir: URL,
        itemProvider: NSItemProvider,
        suggestedName: String?,
        hint: UTType,
        stageProgress: Progress
    ) async throws -> MaterializedUpload {
        if hint.conforms(to: .movie) {
            return try await materializePhotoLibraryVideo(
                parentDir: parentDir,
                itemProvider: itemProvider,
                suggestedName: suggestedName,
                hint: hint,
                stageProgress: stageProgress
            )
        }

        if Self.rawPassthroughImageTypes.contains(hint) {
            return try await materializePhotoLibraryPassthrough(
                parentDir: parentDir,
                itemProvider: itemProvider,
                suggestedName: suggestedName,
                type: hint
            )
        }

        let data = try await loadDataRepresentation(itemProvider: itemProvider, hint: hint)
        try Task.checkCancellation()
        return try finalizeImage(
            data: data,
            declaredType: hint,
            stem: filenames.stem(preferred: suggestedName, fallbackPrefix: "Photo", date: Date()),
            parentDir: parentDir
        )
    }

    /// PHPicker video path. `loadFileRepresentation` hands us a
    /// provider-owned URL valid ONLY during the callback. Copy bytes into
    /// our parentDir inside the callback, then run the export from the
    /// owned copy.
    private func materializePhotoLibraryVideo(
        parentDir: URL,
        itemProvider: NSItemProvider,
        suggestedName: String?,
        hint: UTType,
        stageProgress: Progress
    ) async throws -> MaterializedUpload {
        let copiedSource = try await loadFileRepresentation(
            from: itemProvider,
            typeIdentifier: hint.identifier
        ) { providerURL in
            let sourceExt =
                providerURL.pathExtension.isEmpty
                ? (hint.preferredFilenameExtension ?? "mov")
                : providerURL.pathExtension
            let dest = parentDir.appendingPathComponent("source.\(sourceExt)")
            try FileManager.default.copyItem(at: providerURL, to: dest)
            return dest
        }
        try Task.checkCancellation()

        defer { try? FileManager.default.removeItem(at: copiedSource) }

        return try await finalizeVideo(
            asset: AVURLAsset(url: copiedSource),
            stem: filenames.stem(preferred: suggestedName, fallbackPrefix: "Video", date: Date()),
            parentDir: parentDir,
            stageProgress: stageProgress
        )
    }

    /// PHPicker raw-passthrough path for `rawPassthroughImageTypes`: bytes
    /// copy through the provider untouched, matching V1's
    /// `ItemProviderMediaExporter.processGIF` and V2's `.file` branch for the
    /// same types.
    private func materializePhotoLibraryPassthrough(
        parentDir: URL,
        itemProvider: NSItemProvider,
        suggestedName: String?,
        type: UTType
    ) async throws -> MaterializedUpload {
        let ext = type.preferredFilenameExtension ?? "bin"
        guard policy.isAllowedForUpload(type, ext) else {
            throw MaterializerError.disallowedContentType
        }

        let stem = filenames.stem(preferred: suggestedName, fallbackPrefix: "Photo", date: Date())
        let basename = filenames.basename(stem: stem, ext: ext)
        let destURL = parentDir.appendingPathComponent(basename)

        _ = try await loadFileRepresentation(
            from: itemProvider,
            typeIdentifier: type.identifier
        ) { providerURL in
            try FileManager.default.copyItem(at: providerURL, to: destURL)
            return destURL
        }
        try Task.checkCancellation()

        return MaterializedUpload(
            tempFileURL: destURL,
            params: MediaCreateParams(filePath: destURL.path),
            kind: .image
        )
    }

    // MARK: - Camera

    private func materializeCameraImage(
        parentDir: URL,
        image: UIImage,
        capturedAt: Date
    ) throws -> MaterializedUpload {
        guard
            let jpegData = downscaledForPolicy(image)
                .jpegData(compressionQuality: CGFloat(policy.imageJpegQuality))
        else {
            throw MaterializerError.imageEncodeFailed
        }
        return try finalizeImage(
            data: jpegData,
            declaredType: .jpeg,
            stem: filenames.stem(preferred: nil, fallbackPrefix: "IMG", date: capturedAt),
            parentDir: parentDir
        )
    }

    /// Downscales the in-memory capture to the policy's max dimension BEFORE
    /// the JPEG encode, so a capped capture is encoded exactly once (the
    /// shared image tail then sees an in-cap image and passes the bytes
    /// through). Purely an optimization: if the downscale fails or lands
    /// over the cap, `finalizeImage` resizes as usual.
    private func downscaledForPolicy(_ image: UIImage) -> UIImage {
        guard let cap = policy.imageMaxDimension, cap > 0 else { return image }
        let pixelLongEdge = max(image.size.width, image.size.height) * image.scale
        guard pixelLongEdge > CGFloat(cap) else { return image }
        let ratio = CGFloat(cap) / pixelLongEdge
        let targetPixels = CGSize(
            width: (image.size.width * image.scale * ratio).rounded(),
            height: (image.size.height * image.scale * ratio).rounded()
        )
        // preparingThumbnail takes a pixel size and returns an upright
        // (.up-oriented) image, so the later jpegData carries no stale
        // orientation tag.
        return image.preparingThumbnail(of: targetPixels) ?? image
    }

    private func materializeCameraVideo(
        parentDir: URL,
        sourceURL: URL,
        capturedAt: Date,
        stageProgress: Progress
    ) async throws -> MaterializedUpload {
        try await finalizeVideo(
            asset: AVURLAsset(url: sourceURL),
            stem: filenames.stem(preferred: nil, fallbackPrefix: "IMG", date: capturedAt),
            parentDir: parentDir,
            stageProgress: stageProgress
        )
    }

    /// Re-exports `asset` to `destURL`, driving `stageProgress` from a sibling
    /// poll of `session.progress`.
    ///
    /// `export(to:as:isolation:)` is `@backDeployed` to iOS 13, so the export
    /// runs structured even on the iOS 17 floor: it sets the output URL / file
    /// type itself, observes `Task` cancellation natively, and throws on
    /// failure instead of reporting through a callback. Progress still uses the
    /// legacy `session.progress` property because the modern
    /// `states(updateInterval:)` AsyncSequence is iOS 18+ and not back-deployed.
    private func exportVideo(
        asset: AVURLAsset,
        to destURL: URL,
        outputType: AVFileType,
        stageProgress: Progress
    ) async throws {
        guard
            let exportSession = AVAssetExportSession(
                asset: asset,
                presetName: policy.videoExportPreset
            )
        else {
            throw MaterializerError.videoExportSessionUnavailable
        }
        exportSession.shouldOptimizeForNetworkUse = true
        if policy.stripGPSLocation {
            // `stripGPSLocation` is the single "Remove Location" setting and
            // governs video too. `forSharing()` drops the QuickTime location
            // atom (and other identifying metadata), matching V1
            // MediaVideoExporter.
            exportSession.metadataItemFilter = AVMetadataItemFilter.forSharing()
        }

        // `AVAssetExportSession` isn't `Sendable`, but the poll task only reads
        // `.progress`, which is safe to sample off the originating actor.
        nonisolated(unsafe) let session = exportSession
        let pollTask = Task { [stageProgress] in
            while !Task.isCancelled {
                stageProgress.completedUnitCount = Int64(
                    (Double(stageProgress.totalUnitCount) * Double(session.progress)).rounded()
                )
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        defer { pollTask.cancel() }

        do {
            try await exportSession.export(to: destURL, as: outputType)
        } catch {
            // Let cancellation propagate untouched so the uploader treats it as
            // a cancel rather than a failure; wrap everything else.
            if error is CancellationError { throw error }
            throw MaterializerError.videoExportFailed(underlyingError: error)
        }

        // Snap stageProgress to full — the final poll may have been just shy
        // of 1.0 when export returned.
        stageProgress.completedUnitCount = stageProgress.totalUnitCount
    }

    // MARK: - File

    private func materializeFile(
        parentDir: URL,
        sourceURL: URL,
        stageProgress: Progress
    ) async throws -> MaterializedUpload {
        guard sourceURL.startAccessingSecurityScopedResource() else {
            throw MaterializerError.securityScopedAccessDenied
        }
        defer { sourceURL.stopAccessingSecurityScopedResource() }

        let contentType = try resolveContentType(of: sourceURL)
        let stem = filenames.stem(
            preferred: sourceURL.deletingPathExtension().lastPathComponent,
            fallbackPrefix: "File",
            date: Date()
        )

        // Raw-passthrough types (GIF, SVG) must not be re-encoded, so they
        // raw-copy like any other passthrough file. Every other image goes
        // through the shared image tail.
        if contentType.conforms(to: .image), !Self.rawPassthroughImageTypes.contains(contentType) {
            return try materializeFileImage(
                parentDir: parentDir,
                sourceURL: sourceURL,
                contentType: contentType,
                stem: stem
            )
        }
        if contentType.conforms(to: .movie) {
            return try await materializeFileVideo(
                parentDir: parentDir,
                sourceURL: sourceURL,
                stem: stem,
                stageProgress: stageProgress
            )
        }
        return try materializeFileRawCopy(
            parentDir: parentDir,
            sourceURL: sourceURL,
            contentType: contentType,
            stem: stem
        )
    }

    private func materializeFileImage(
        parentDir: URL,
        sourceURL: URL,
        contentType: UTType,
        stem: String
    ) throws -> MaterializedUpload {
        let data = try Data(contentsOf: sourceURL)
        return try finalizeImage(
            data: data,
            declaredType: contentType,
            stem: stem,
            parentDir: parentDir
        )
    }

    /// Image Playground returns a local file URL inside our own sandbox — no
    /// security-scoped access required. Resolves the URL's UTType with a
    /// defensive `.heic` fallback (matches V1 `MediaPickerMenu+ImagePlayground`
    /// behavior) and dispatches to the existing image policy path.
    private func materializeImagePlayground(
        parentDir: URL,
        sourceURL: URL,
        suggestedName: String
    ) throws -> MaterializedUpload {
        // V1 fallback (MediaPickerMenu+ImagePlayground.swift:46-55).
        let resolvedType = sourceURL.resolvedContentType ?? .heic

        return try materializeFileImage(
            parentDir: parentDir,
            sourceURL: sourceURL,
            contentType: resolvedType,
            stem: suggestedName
        )
    }

    private func materializeFileVideo(
        parentDir: URL,
        sourceURL: URL,
        stem: String,
        stageProgress: Progress
    ) async throws -> MaterializedUpload {
        try await finalizeVideo(
            asset: AVURLAsset(url: sourceURL),
            stem: stem,
            parentDir: parentDir,
            stageProgress: stageProgress
        )
    }

    private func materializeFileRawCopy(
        parentDir: URL,
        sourceURL: URL,
        contentType: UTType,
        stem: String
    ) throws -> MaterializedUpload {
        let ext = sourceURL.pathExtension.isEmpty ? "bin" : sourceURL.pathExtension
        guard policy.isAllowedForUpload(contentType, ext) else {
            throw MaterializerError.disallowedContentType
        }
        let basename = filenames.basename(stem: stem, ext: ext)
        let destURL = parentDir.appendingPathComponent(basename)
        try FileManager.default.copyItem(at: sourceURL, to: destURL)
        return MaterializedUpload(
            tempFileURL: destURL,
            params: MediaCreateParams(filePath: destURL.path),
            kind: MediaKind(estimating: contentType)
        )
    }

    // MARK: - Remote URL (post-download dispatch)

    /// `.remoteURL` = download phase (RemoteDownloader writes bytes into
    /// `parentDir`) then dispatch phase (`dispatchRemoteDownload`). `parentDir`
    /// is created and cleaned up by `materialize`, so neither phase manages it.
    private func materializeRemoteURL(
        parentDir: URL,
        remote: UploadSource.RemoteURL,
        stageProgress: Progress
    ) async throws -> MaterializedUpload {
        // TODO: failed `.remoteURL` materialization is currently
        // Dismiss-only (FailedUpload.isRetryable: materialized != nil).
        // Retaining the original UploadSource on failed entries would
        // let Retry re-run materialization for this case (and every
        // other materialization-failing source).
        let localFile = try await remoteDownloader.download(
            from: remote.url,
            into: parentDir,
            progress: stageProgress
        )
        return try await dispatchRemoteDownload(
            localFile: localFile,
            contentType: remote.contentType,
            suggestedName: remote.suggestedName,
            caption: remote.caption,
            parentDir: parentDir
        )
    }

    /// Post-download dispatch for `.remoteURL`. Takes a local file (already
    /// downloaded into `parentDir`), the declared content type, the sanitized
    /// suggested-name stem, and an optional caption. Assumes `parentDir`
    /// exists — `materialize` owns its creation and cleanup. Branches:
    /// raw-passthrough types (GIF, SVG) → move bytes to `<stem>.<ext>`
    /// untouched; any other image → the shared image tail (which validates
    /// the bytes, so an HTML error body served as image/jpeg is rejected);
    /// anything else → MaterializerError.disallowedContentType.
    ///
    /// Kept module-internal as a test seam so the post-download dispatch can be
    /// exercised without a live network download.
    func dispatchRemoteDownload(
        localFile: URL,
        contentType: UTType,
        suggestedName: String,
        caption: String?,
        parentDir: URL
    ) async throws -> MaterializedUpload {
        if Self.rawPassthroughImageTypes.contains(contentType) {
            return try materializeRemotePassthrough(
                localFile: localFile,
                type: contentType,
                stem: suggestedName,
                caption: caption,
                parentDir: parentDir
            )
        } else if contentType.conforms(to: .image) {
            let data = try Data(contentsOf: localFile)
            return try finalizeImage(
                data: data,
                declaredType: contentType,
                stem: suggestedName,
                caption: caption,
                parentDir: parentDir
            )
        } else {
            throw MaterializerError.disallowedContentType
        }
    }

    /// Raw passthrough for remote GIF/SVG: moves the downloaded bytes to
    /// `<stem>.<ext>` in our owned parentDir, ignoring whatever extension
    /// URLSession's temp file had. GIF mirrors V1's
    /// MediaExternalExporter.swift:63-74; SVG is new in V2 (V1 rasterized
    /// it). The bytes are not validated — these types can't round-trip
    /// through ImageIO, so the server allow-list (via the policy check) is
    /// the gate, same as the local `.file` path.
    private func materializeRemotePassthrough(
        localFile: URL,
        type: UTType,
        stem: String,
        caption: String?,
        parentDir: URL
    ) throws -> MaterializedUpload {
        let ext = type.preferredFilenameExtension ?? "bin"
        guard policy.isAllowedForUpload(type, ext) else {
            throw MaterializerError.disallowedContentType
        }
        let basename = filenames.basename(stem: stem, ext: ext)
        let destURL = parentDir.appendingPathComponent(basename)
        try FileManager.default.moveItem(at: localFile, to: destURL)
        return MaterializedUpload(
            tempFileURL: destURL,
            params: MediaCreateParams(caption: caption, filePath: destURL.path),
            kind: .image
        )
    }

    // MARK: - Shared finalize

    /// The set of transforms the single-pass image write must apply, computed
    /// once from the image header and the policy.
    private struct ImageTransforms: OptionSet {
        let rawValue: Int

        static let convert = ImageTransforms(rawValue: 1 << 0)
        static let resize = ImageTransforms(rawValue: 1 << 1)
        static let stripGPS = ImageTransforms(rawValue: 1 << 2)
    }

    /// Shared image tail: header-validate, sniff the real content type,
    /// allow-check, then apply every needed transform (JPEG conversion,
    /// resize, GPS strip) in a single ImageIO pass and write into
    /// `parentDir`. Callers supply only the declared type, name stem, and
    /// optional caption. `parentDir` is created and cleaned up by the
    /// `materialize` entry point.
    ///
    /// The bytes are decoded at most once and encoded at most once. When no
    /// transform is needed the input bytes are written unchanged, so web-safe
    /// in-cap images survive byte-for-byte. Any ImageIO failure throws — the
    /// transform never falls back to the original bytes, so a required GPS
    /// strip can never silently ship the location.
    ///
    /// Validation is header-level: a non-image body (e.g. an HTML error page
    /// served as image/jpeg) is rejected, but a truncated image with an
    /// intact header still passes, matching V1.
    private func finalizeImage(
        data: Data,
        declaredType: UTType,
        stem: String,
        caption: String? = nil,
        parentDir: URL
    ) throws -> MaterializedUpload {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            CGImageSourceGetCount(source) >= 1,
            let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = props[kCGImagePropertyPixelWidth] as? Int,
            let height = props[kCGImagePropertyPixelHeight] as? Int
        else {
            throw MaterializerError.invalidImageData
        }

        // The sniffed container type is the truth; the declared type (picker
        // hint, Content-Type header, file extension) can lie — a HEIC served
        // as image/jpeg must still be converted.
        let actualType = CGImageSourceGetType(source).flatMap { UTType($0 as String) } ?? declaredType

        var transforms: ImageTransforms = []
        var effectiveType = actualType
        if !Self.webSafeImageTypes.contains(actualType), policy.convertHEICToJPEG {
            effectiveType = .jpeg
            transforms.insert(.convert)
        }
        if let cap = policy.imageMaxDimension, cap > 0, max(width, height) > cap {
            transforms.insert(.resize)
        }
        if policy.stripGPSLocation, props[kCGImagePropertyGPSDictionary] != nil {
            transforms.insert(.stripGPS)
        }
        // A transform re-encodes, and the re-encode target must be
        // web-renderable and ImageIO-writable (e.g. an oversized DNG with
        // HEIC conversion disabled still can't be written back as DNG).
        if !transforms.isEmpty, !Self.webSafeImageTypes.contains(effectiveType) {
            effectiveType = .jpeg
        }

        let ext =
            effectiveType.preferredFilenameExtension
            ?? declaredType.preferredFilenameExtension ?? "bin"
        guard policy.isAllowedForUpload(effectiveType, ext) else {
            throw MaterializerError.disallowedContentType
        }

        let output =
            transforms.isEmpty
            ? data
            : try transformImage(
                source: source,
                sourceProperties: props,
                to: effectiveType,
                applying: transforms
            )

        let basename = filenames.basename(stem: stem, ext: ext)
        let destURL = parentDir.appendingPathComponent(basename)
        try output.write(to: destURL)
        return MaterializedUpload(
            tempFileURL: destURL,
            params: MediaCreateParams(caption: caption, filePath: destURL.path),
            kind: .image
        )
    }

    /// Single ImageIO write applying `transforms`: exactly one decode and one
    /// encode. Three strategies, chosen to preserve the EXIF orientation tag
    /// whenever pixels are not resampled (a dropped tag once shipped rotated
    /// HEIC uploads):
    /// - resize: thumbnail with the rotation baked into the pixels, the tag
    ///   stamped upright, and the remaining metadata carried over — the same
    ///   treatment as V1 `MediaImageExporter.ImageSourceWriter`.
    /// - GPS strip without resize: unrotated pixel decode with the source
    ///   properties (minus GPS) re-attached; the tag rides along in the
    ///   properties, staying paired with the unrotated pixels.
    /// - conversion only: `CGImageDestinationAddImageFromSource`, which
    ///   carries pixels and metadata across the container change untouched.
    private func transformImage(
        source: CGImageSource,
        sourceProperties: [CFString: Any],
        to effectiveType: UTType,
        applying transforms: ImageTransforms
    ) throws -> Data {
        let out = NSMutableData()
        guard
            let dst = CGImageDestinationCreateWithData(
                out,
                effectiveType.identifier as CFString,
                1,
                nil
            )
        else {
            throw MaterializerError.imageEncodeFailed
        }

        if transforms.contains(.resize) {
            let thumbnailOptions: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: policy.imageMaxDimension ?? 0
            ]
            guard
                let thumb = CGImageSourceCreateThumbnailAtIndex(
                    source,
                    0,
                    thumbnailOptions as CFDictionary
                )
            else {
                throw MaterializerError.imageEncodeFailed
            }
            var props = sourceProperties
            if transforms.contains(.stripGPS) {
                props.removeValue(forKey: kCGImagePropertyGPSDictionary)
            }
            // The thumbnail baked the EXIF rotation into the pixels, so stamp
            // the orientation upright everywhere it lives (V1 parity) and drop
            // the stale pixel-dimension records; the destination writes the
            // real dimensions itself.
            props[kCGImagePropertyOrientation] = CGImagePropertyOrientation.up.rawValue
            if var tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
                tiff.removeValue(forKey: kCGImagePropertyTIFFOrientation)
                props[kCGImagePropertyTIFFDictionary] = tiff
            }
            if var iptc = props[kCGImagePropertyIPTCDictionary] as? [CFString: Any] {
                iptc.removeValue(forKey: kCGImagePropertyIPTCImageOrientation)
                props[kCGImagePropertyIPTCDictionary] = iptc
            }
            if var exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any] {
                exif.removeValue(forKey: kCGImagePropertyExifPixelXDimension)
                exif.removeValue(forKey: kCGImagePropertyExifPixelYDimension)
                props[kCGImagePropertyExifDictionary] = exif
            }
            props.removeValue(forKey: kCGImagePropertyPixelWidth)
            props.removeValue(forKey: kCGImagePropertyPixelHeight)
            props[kCGImageDestinationLossyCompressionQuality] = policy.imageJpegQuality
            CGImageDestinationAddImage(dst, thumb, props as CFDictionary)
        } else if transforms.contains(.stripGPS) {
            guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw MaterializerError.locationStripFailed
            }
            var props = sourceProperties
            props.removeValue(forKey: kCGImagePropertyGPSDictionary)
            props[kCGImageDestinationLossyCompressionQuality] = policy.imageJpegQuality
            CGImageDestinationAddImage(dst, image, props as CFDictionary)
        } else {
            // Copy the image straight from source to destination. ImageIO
            // carries the orientation tag (and other metadata) across the
            // container change, so the stored pixels stay paired with their
            // orientation. Decoding to a bare CGImage and re-adding it would
            // drop the tag and render a non-upright source (e.g. a
            // 180°-oriented HEIC) upside down.
            CGImageDestinationAddImageFromSource(
                dst,
                source,
                0,
                [kCGImageDestinationLossyCompressionQuality: policy.imageJpegQuality]
                    as CFDictionary
            )
        }

        guard CGImageDestinationFinalize(dst) else {
            throw transforms.contains(.stripGPS)
                ? MaterializerError.locationStripFailed
                : MaterializerError.imageEncodeFailed
        }
        return out as Data
    }

    /// Shared video tail: duration cap, allow-check, then re-export `asset`
    /// into `parentDir`. The output container and extension come from the
    /// policy; callers supply only the asset and the name stem.
    private func finalizeVideo(
        asset: AVURLAsset,
        stem: String,
        parentDir: URL,
        stageProgress: Progress
    ) async throws -> MaterializedUpload {
        let duration = try await asset.load(.duration).seconds
        if let cap = policy.videoMaxDurationSeconds, duration > cap {
            throw MaterializerError.durationCapExceeded
        }
        let outputType = AVFileType(rawValue: policy.videoOutputContentType.identifier)
        let ext = policy.videoOutputContentType.preferredFilenameExtension ?? "mp4"
        guard policy.isAllowedForUpload(policy.videoOutputContentType, ext) else {
            throw MaterializerError.disallowedContentType
        }
        let basename = filenames.basename(stem: stem, ext: ext)
        let destURL = parentDir.appendingPathComponent(basename)
        try await exportVideo(
            asset: asset,
            to: destURL,
            outputType: outputType,
            stageProgress: stageProgress
        )
        return MaterializedUpload(
            tempFileURL: destURL,
            params: MediaCreateParams(filePath: destURL.path),
            kind: .video
        )
    }

    // MARK: - Helpers

    /// Creates the staging root (once) and excludes it from backup, so
    /// materialized media never lands in the user's iCloud/device backup.
    private func ensureStagingRoot() throws {
        guard !FileManager.default.fileExists(atPath: temporaryRoot.path) else { return }
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        var root = temporaryRoot
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? root.setResourceValues(values)
    }

    private func loadDataRepresentation(
        itemProvider: NSItemProvider,
        hint: UTType
    ) async throws -> Data {
        try await providerLoad { completion in
            itemProvider.loadDataRepresentation(
                forTypeIdentifier: hint.identifier,
                completionHandler: completion
            )
        }
    }

    /// Loads a provider file representation, invoking `body` with the
    /// provider-owned URL *inside* the completion (that URL is valid only
    /// there).
    private func loadFileRepresentation<T: Sendable>(
        from itemProvider: NSItemProvider,
        typeIdentifier: String,
        _ body: @escaping @Sendable (URL) throws -> T
    ) async throws -> T {
        try await providerLoad { completion in
            itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, err in
                guard let url, err == nil else {
                    completion(nil, err)
                    return
                }
                do {
                    completion(try body(url), nil)
                } catch {
                    completion(nil, error)
                }
            }
        }
    }

    /// Bridges an `NSItemProvider` load API to async. `start` receives a
    /// completion to hand to the provider and returns the load's `Progress`.
    /// A `nil` value with a `nil` error surfaces as `fileNotFound`. Wrapped in
    /// a cancellation handler that cancels the provider load, so tapping
    /// Cancel during a large iCloud fetch stops the download instead of
    /// running it to completion and discarding the result.
    private func providerLoad<T: Sendable>(
        _ start: (@escaping @Sendable (T?, Error?) -> Void) -> Progress
    ) async throws -> T {
        let box = ProgressBox()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<T, Error>) in
                let progress = start { value, err in
                    if let err {
                        cont.resume(throwing: err)
                    } else if let value {
                        cont.resume(returning: value)
                    } else {
                        cont.resume(throwing: MaterializerError.fileNotFound)
                    }
                }
                box.set(progress)
            }
        } onCancel: {
            box.cancel()
        }
    }

    /// Image types that must never round-trip through ImageIO: re-encoding
    /// would flatten GIF animation and rasterize SVG vectors. Every source
    /// branch routes these to a raw byte copy instead of the image tail.
    /// (Animated WebP and APNG are not exempt: WebP converts to a JPEG still
    /// and an oversized APNG resizes to a single frame, matching V1.)
    private static let rawPassthroughImageTypes: Set<UTType> = [.gif, .svg]

    /// Raster types that upload without format conversion. Everything else
    /// (HEIC, HEIF, TIFF, WebP, BMP, DNG, ...) is converted to JPEG, matching
    /// V1 `ItemProviderMediaExporter.supportedImageTypes`. GIF and SVG never
    /// reach the image tail — they are `rawPassthroughImageTypes`.
    private static let webSafeImageTypes: Set<UTType> = [.png, .jpeg]

    private func resolveContentType(of url: URL) throws -> UTType {
        guard let type = url.resolvedContentType else {
            throw MaterializerError.unknownContentType
        }
        return type
    }
}

/// Thread-safe holder so a task-cancellation handler can cancel a provider
/// load's `Progress`, which is produced synchronously right after the
/// continuation body starts running.
private final class ProgressBox: @unchecked Sendable {
    private let stored = OSAllocatedUnfairLock<Progress?>(initialState: nil)
    func set(_ value: Progress) { stored.withLock { $0 = value } }
    func cancel() { stored.withLock { $0?.cancel() } }
}
