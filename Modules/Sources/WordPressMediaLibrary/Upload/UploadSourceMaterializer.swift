import AVFoundation
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers
import WordPressAPI

struct MaterializedUpload: Sendable {
    let tempFileURL: URL
    let params: MediaCreateParams
    let kind: MediaKind
    let displayName: String
}

/// Test seam over `UploadSourceMaterializer.materialize`. The actor talks
/// to materialization via this protocol so tests can substitute a mock.
protocol MediaSourceMaterializing: Sendable {
    func materialize(
        source: UploadSource,
        into stageProgress: Progress
    ) async throws -> MaterializedUpload
}

final class UploadSourceMaterializer: MediaSourceMaterializing, Sendable {
    private let policy: MediaUploadPolicy
    private let temporaryRoot: URL
    private let filenames = UploadFilenameAllocator()

    init(
        policy: MediaUploadPolicy,
        temporaryRoot: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("WordPressMediaLibrary-Uploads", isDirectory: true)
    ) {
        self.policy = policy
        self.temporaryRoot = temporaryRoot
    }

    func materialize(
        source: UploadSource,
        into stageProgress: Progress
    ) async throws -> MaterializedUpload {
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

        if hint == .gif {
            return try await materializePhotoLibraryGIF(
                parentDir: parentDir,
                itemProvider: itemProvider,
                suggestedName: suggestedName
            )
        }

        let data = try await loadDataRepresentation(itemProvider: itemProvider, hint: hint)
        let (outputData, effectiveType) = try convertHEICIfNeeded(data, type: hint)
        return try finalizeImage(
            data: outputData,
            effectiveType: effectiveType,
            ext: effectiveType.preferredFilenameExtension ?? hint.preferredFilenameExtension ?? "bin",
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
        let copiedSource: URL = try await withCheckedThrowingContinuation { cont in
            itemProvider.loadFileRepresentation(
                forTypeIdentifier: hint.identifier
            ) { providerURL, err in
                if let err {
                    cont.resume(throwing: err)
                    return
                }
                guard let providerURL else {
                    cont.resume(throwing: MaterializerError.fileNotFound); return
                }
                let sourceExt =
                    providerURL.pathExtension.isEmpty
                    ? (hint.preferredFilenameExtension ?? "mov")
                    : providerURL.pathExtension
                let dest = parentDir.appendingPathComponent("source.\(sourceExt)")
                do {
                    try FileManager.default.copyItem(at: providerURL, to: dest)
                    cont.resume(returning: dest)
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }

        defer { try? FileManager.default.removeItem(at: copiedSource) }

        return try await finalizeVideo(
            asset: AVURLAsset(url: copiedSource),
            stem: filenames.stem(preferred: suggestedName, fallbackPrefix: "Video", date: Date()),
            parentDir: parentDir,
            stageProgress: stageProgress
        )
    }

    /// PHPicker GIF path. ImageIO's thumbnail/encode round-trip used by
    /// `resizeIfNeeded` and `stripGPS` would flatten animation to a single
    /// frame, so GIFs raw-copy bytes through the provider — matching V1's
    /// `ItemProviderMediaExporter.processGIF` and V2's `.file` GIF branch.
    private func materializePhotoLibraryGIF(
        parentDir: URL,
        itemProvider: NSItemProvider,
        suggestedName: String?
    ) async throws -> MaterializedUpload {
        guard policy.isAllowedForUpload(.gif, "gif") else {
            throw MaterializerError.disallowedContentType
        }

        let stem = filenames.stem(preferred: suggestedName, fallbackPrefix: "Photo", date: Date())
        let basename = filenames.basename(stem: stem, ext: "gif")
        let destURL = parentDir.appendingPathComponent(basename)

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            itemProvider.loadFileRepresentation(
                forTypeIdentifier: UTType.gif.identifier
            ) { providerURL, err in
                if let err {
                    cont.resume(throwing: err)
                    return
                }
                guard let providerURL else {
                    cont.resume(throwing: MaterializerError.fileNotFound); return
                }
                do {
                    try FileManager.default.copyItem(at: providerURL, to: destURL)
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }

        return MaterializedUpload(
            tempFileURL: destURL,
            params: MediaCreateParams(filePath: destURL.path),
            kind: .image,
            displayName: basename
        )
    }

    // MARK: - Camera

    func materializeCameraImage(
        parentDir: URL,
        image: UIImage,
        capturedAt: Date
    ) throws -> MaterializedUpload {
        guard let jpegData = image.jpegData(compressionQuality: CGFloat(policy.imageJpegQuality))
        else {
            throw MaterializerError.heicConversionFailed
        }
        return try finalizeImage(
            data: jpegData,
            effectiveType: .jpeg,
            ext: "jpg",
            stem: filenames.stem(preferred: nil, fallbackPrefix: "IMG", date: capturedAt),
            parentDir: parentDir
        )
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
            throw MaterializerError.videoExportFailed(
                underlyingError: VideoExportFailureReason.noExporterForPreset
            )
        }
        exportSession.shouldOptimizeForNetworkUse = true

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

        if contentType.conforms(to: .image) && contentType != .gif {
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

    func materializeFileImage(
        parentDir: URL,
        sourceURL: URL,
        contentType: UTType,
        stem: String,
        caption: String? = nil
    ) throws -> MaterializedUpload {
        let data = try Data(contentsOf: sourceURL)
        let (converted, effectiveType) = try convertHEICIfNeeded(data, type: contentType)
        return try finalizeImage(
            data: converted,
            effectiveType: effectiveType,
            ext: effectiveType.preferredFilenameExtension ?? sourceURL.pathExtension,
            stem: stem,
            caption: caption,
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
        let resolvedType: UTType = {
            if let type = try? sourceURL.resourceValues(forKeys: [.contentTypeKey]).contentType {
                return type
            }
            return .heic // V1 fallback (MediaPickerMenu+ImagePlayground.swift:46-55)
        }()

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
            kind: MediaKind(estimating: contentType),
            displayName: basename
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
        let downloader = RemoteDownloader()
        let localFile = try await downloader.download(
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
    /// exists — `materialize` owns its creation and cleanup. Branches: GIF →
    /// write to `<stem>.gif` raw; image (non-GIF) → byte-validate then
    /// materializeFileImage; anything else → MaterializerError.disallowedContentType.
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
        if contentType == .gif {
            return try materializeRemoteGIF(
                localFile: localFile,
                stem: suggestedName,
                caption: caption,
                parentDir: parentDir
            )
        } else if contentType.conforms(to: .image) {
            return try materializeRemoteImage(
                localFile: localFile,
                contentType: contentType,
                stem: suggestedName,
                caption: caption,
                parentDir: parentDir
            )
        } else {
            throw MaterializerError.disallowedContentType
        }
    }

    /// GIF passthrough: writes downloaded bytes to `<stem>.gif` in our owned
    /// parentDir, ignoring whatever extension URLSession's temp file had.
    /// Mirrors V1's MediaExternalExporter.swift:63-74.
    private func materializeRemoteGIF(
        localFile: URL,
        stem: String,
        caption: String?,
        parentDir: URL
    ) throws -> MaterializedUpload {
        guard policy.isAllowedForUpload(.gif, "gif") else {
            throw MaterializerError.disallowedContentType
        }
        let basename = filenames.basename(stem: stem, ext: "gif")
        let destURL = parentDir.appendingPathComponent(basename)
        try FileManager.default.moveItem(at: localFile, to: destURL)
        return MaterializedUpload(
            tempFileURL: destURL,
            params: MediaCreateParams(caption: caption, filePath: destURL.path),
            kind: .image,
            displayName: basename
        )
    }

    /// Image branch: decode-validate bytes (UIImage(data:)-equivalent via
    /// CGImageSource) BEFORE materializeFileImage; without this, the resize
    /// and GPS-strip helpers return original bytes on decode failure, so a
    /// Pexels HTML error response would upload as 'allowed JPEG'. The caption
    /// is threaded through `materializeFileImage` so V1 Stock Photos attribution
    /// lands in `MediaCreateParams.caption`.
    private func materializeRemoteImage(
        localFile: URL,
        contentType: UTType,
        stem: String,
        caption: String?,
        parentDir: URL
    ) throws -> MaterializedUpload {
        let data = try Data(contentsOf: localFile)
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            CGImageSourceCreateImageAtIndex(source, 0, nil) != nil
        else {
            throw MaterializerError.remoteDownloadFailed(
                underlyingError: NSError(
                    domain: "RemoteImageValidation",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Downloaded bytes are not a valid image."]
                )
            )
        }
        // Reuse the bytes just read for validation instead of letting
        // materializeFileImage re-read the file from disk. Mirrors the
        // in-memory tail of materializePhotoLibrary.
        let (converted, effectiveType) = try convertHEICIfNeeded(data, type: contentType)
        let ext = effectiveType.preferredFilenameExtension ?? localFile.pathExtension
        return try finalizeImage(
            data: converted,
            effectiveType: effectiveType,
            ext: ext,
            stem: stem,
            caption: caption,
            parentDir: parentDir
        )
    }

    // MARK: - Shared finalize

    /// Shared image tail: resize, optional GPS strip, allow-check, then write
    /// into `parentDir`. Callers supply the already-decided effective type,
    /// file extension, name stem, and optional caption — everything that
    /// differs per source. `parentDir` is created and cleaned up by the
    /// `materialize` entry point.
    private func finalizeImage(
        data: Data,
        effectiveType: UTType,
        ext: String,
        stem: String,
        caption: String? = nil,
        parentDir: URL
    ) throws -> MaterializedUpload {
        let resized = try resizeIfNeeded(data: data, contentType: effectiveType)
        let stripped =
            policy.stripImageLocation
            ? try stripGPS(data: resized, contentType: effectiveType)
            : resized

        guard policy.isAllowedForUpload(effectiveType, ext) else {
            throw MaterializerError.disallowedContentType
        }
        let basename = filenames.basename(stem: stem, ext: ext)
        let destURL = parentDir.appendingPathComponent(basename)
        try stripped.write(to: destURL)
        return MaterializedUpload(
            tempFileURL: destURL,
            params: MediaCreateParams(caption: caption, filePath: destURL.path),
            kind: .image,
            displayName: basename
        )
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
            kind: .video,
            displayName: basename
        )
    }

    // MARK: - Helpers

    private func loadDataRepresentation(
        itemProvider: NSItemProvider,
        hint: UTType
    ) async throws -> Data {
        try await withCheckedThrowingContinuation { cont in
            itemProvider.loadDataRepresentation(forTypeIdentifier: hint.identifier) { data, err in
                if let err {
                    cont.resume(throwing: err)
                    return
                }
                guard let data else {
                    cont.resume(throwing: MaterializerError.fileNotFound); return
                }
                cont.resume(returning: data)
            }
        }
    }

    /// Converts HEIC bytes to JPEG when the policy asks for it, returning the
    /// effective content type alongside. Non-HEIC input (or HEIC under a policy
    /// that keeps it) passes through untouched.
    private func convertHEICIfNeeded(_ data: Data, type contentType: UTType) throws -> (Data, UTType) {
        guard contentType == .heic, policy.convertHEICToJPEG else {
            return (data, contentType)
        }
        return (try heicToJPEG(data: data), .jpeg)
    }

    private func heicToJPEG(data: Data) throws -> Data {
        guard
            let src = CGImageSourceCreateWithData(data as CFData, nil),
            let cgImage = CGImageSourceCreateImageAtIndex(src, 0, nil)
        else {
            throw MaterializerError.heicConversionFailed
        }
        let mutable = NSMutableData()
        guard
            let dst = CGImageDestinationCreateWithData(
                mutable,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        else {
            throw MaterializerError.heicConversionFailed
        }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: policy.imageJpegQuality
        ]
        CGImageDestinationAddImage(dst, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(dst) else {
            throw MaterializerError.heicConversionFailed
        }
        return mutable as Data
    }

    private func resizeIfNeeded(data: Data, contentType: UTType) throws -> Data {
        guard
            let max = policy.imageMaxDimension, max > 0,
            let src = CGImageSourceCreateWithData(data as CFData, nil)
        else {
            return data
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max
        ]
        guard
            let thumb = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary)
        else {
            return data
        }
        let out = NSMutableData()
        guard
            let dst = CGImageDestinationCreateWithData(
                out,
                contentType.identifier as CFString,
                1,
                nil
            )
        else {
            return data
        }
        let writeOptions: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: policy.imageJpegQuality
        ]
        CGImageDestinationAddImage(dst, thumb, writeOptions as CFDictionary)
        guard CGImageDestinationFinalize(dst) else { return data }
        return out as Data
    }

    private func stripGPS(data: Data, contentType: UTType) throws -> Data {
        guard
            let src = CGImageSourceCreateWithData(data as CFData, nil),
            let cgImage = CGImageSourceCreateImageAtIndex(src, 0, nil)
        else { return data }
        let out = NSMutableData()
        guard
            let dst = CGImageDestinationCreateWithData(
                out,
                contentType.identifier as CFString,
                1,
                nil
            )
        else { return data }
        // Build a clean properties dict without the GPS entry. We decode the
        // source pixel data (cgImage) and re-encode it with the stripped props
        // rather than copying from source, which would carry over GPS metadata
        // even if we set the key to nil in the options dict.
        var props =
            (CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any]) ?? [:]
        props.removeValue(forKey: kCGImagePropertyGPSDictionary)
        props[kCGImageDestinationLossyCompressionQuality] = policy.imageJpegQuality
        CGImageDestinationAddImage(dst, cgImage, props as CFDictionary)
        guard CGImageDestinationFinalize(dst) else { return data }
        return out as Data
    }

    private func resolveContentType(of url: URL) throws -> UTType {
        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            return type
        }
        if let type = UTType(filenameExtension: url.pathExtension) {
            return type
        }
        throw MaterializerError.unknownContentType
    }
}
