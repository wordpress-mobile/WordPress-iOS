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
    let displayName: String
}

enum VideoExportFailureReason: Error {
    case noExporterForPreset
    /// `AVAssetExportSession` reported `.failed` or `.cancelled` without
    /// populating `session.error`.
    case missingUnderlyingError
    case unexpectedStatus(AVAssetExportSession.Status)
}

enum MaterializerError: LocalizedError {
    case securityScopedAccessDenied
    case fileNotFound
    case durationCapExceeded
    case disallowedContentType
    case heicConversionFailed
    case videoExportFailed(Error)
    case tempWriteFailed(Error)
    case unknownContentType

    var errorDescription: String? {
        switch self {
        case .securityScopedAccessDenied: return Strings.uploadErrorSecurityScopedAccess
        case .fileNotFound: return Strings.uploadErrorFileNotFound
        case .durationCapExceeded: return Strings.uploadErrorDurationCap
        case .disallowedContentType: return Strings.uploadErrorDisallowedType
        case .heicConversionFailed: return Strings.uploadErrorHEICConversion
        case .videoExportFailed: return Strings.uploadErrorVideoExport
        case .tempWriteFailed: return Strings.uploadErrorTempWrite
        case .unknownContentType: return Strings.uploadErrorUnknownContentType
        }
    }
}

// `Error` associated values are not `Equatable`, so equality is defined by case
// discriminant only. The wrapped error is intentionally ignored here — callers
// that care about the underlying cause should inspect `errorDescription` or
// cast to a concrete type.
extension MaterializerError: Equatable {
    static func == (lhs: MaterializerError, rhs: MaterializerError) -> Bool {
        switch (lhs, rhs) {
        case (.securityScopedAccessDenied, .securityScopedAccessDenied),
            (.fileNotFound, .fileNotFound),
            (.durationCapExceeded, .durationCapExceeded),
            (.disallowedContentType, .disallowedContentType),
            (.heicConversionFailed, .heicConversionFailed),
            (.videoExportFailed, .videoExportFailed),
            (.tempWriteFailed, .tempWriteFailed),
            (.unknownContentType, .unknownContentType):
            return true
        default:
            return false
        }
    }
}

/// Test seam over `URL.startAccessingSecurityScopedResource()` /
/// `URL.stopAccessingSecurityScopedResource()`.
protocol SecurityScopedAccessor: Sendable {
    func start(_ url: URL) -> Bool
    func stop(_ url: URL)
}

struct DefaultSecurityScopedAccessor: SecurityScopedAccessor {
    func start(_ url: URL) -> Bool { url.startAccessingSecurityScopedResource() }
    func stop(_ url: URL) { url.stopAccessingSecurityScopedResource() }
}

/// Carries a non-Sendable reference across `@Sendable` closure boundaries
/// for cases where the captured object is documented thread-safe for the
/// methods we call (e.g. `AVAssetExportSession.progress` /
/// `cancelExport()`). Use sparingly.
private struct UnsafeSendableBox<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
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
    private let securityScopedAccessor: any SecurityScopedAccessor
    private let usedBasenames = OSAllocatedUnfairLock<Set<String>>(initialState: [])

    init(
        policy: MediaUploadPolicy,
        temporaryRoot: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("WordPressMediaLibrary-Uploads", isDirectory: true),
        securityScopedAccessor: any SecurityScopedAccessor = DefaultSecurityScopedAccessor()
    ) {
        self.policy = policy
        self.temporaryRoot = temporaryRoot
        self.securityScopedAccessor = securityScopedAccessor
    }

    func materialize(
        source: UploadSource,
        into stageProgress: Progress
    ) async throws -> MaterializedUpload {
        let id = UUID()
        let parentDir = temporaryRoot.appendingPathComponent(id.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)

        do {
            let result: MaterializedUpload
            switch source {
            case .photoLibrary(let itemProvider, let suggestedName, let hint):
                result = try await materializePhotoLibrary(
                    id: id,
                    parentDir: parentDir,
                    itemProvider: itemProvider,
                    suggestedName: suggestedName,
                    hint: hint,
                    stageProgress: stageProgress
                )
            case .cameraImage(let image, let capturedAt):
                result = try materializeCameraImage(
                    id: id,
                    parentDir: parentDir,
                    image: image,
                    capturedAt: capturedAt
                )
            case .cameraVideo(let url, let capturedAt):
                result = try await materializeCameraVideo(
                    id: id,
                    parentDir: parentDir,
                    sourceURL: url,
                    capturedAt: capturedAt,
                    stageProgress: stageProgress
                )
            case .file(let url):
                result = try await materializeFile(
                    id: id,
                    parentDir: parentDir,
                    sourceURL: url,
                    stageProgress: stageProgress
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
        id: UUID,
        parentDir: URL,
        itemProvider: NSItemProvider,
        suggestedName: String?,
        hint: UTType,
        stageProgress: Progress
    ) async throws -> MaterializedUpload {
        if hint.conforms(to: .movie) {
            return try await materializePhotoLibraryVideo(
                id: id,
                parentDir: parentDir,
                itemProvider: itemProvider,
                suggestedName: suggestedName,
                hint: hint,
                stageProgress: stageProgress
            )
        }

        if hint == .gif {
            return try await materializePhotoLibraryGIF(
                id: id,
                parentDir: parentDir,
                itemProvider: itemProvider,
                suggestedName: suggestedName
            )
        }

        let data = try await loadDataRepresentation(itemProvider: itemProvider, hint: hint)
        let effectiveType: UTType
        let outputData: Data
        if hint == .heic && policy.convertHEICToJPEG {
            outputData = try heicToJPEG(data: data)
            effectiveType = .jpeg
        } else {
            outputData = data
            effectiveType = hint
        }
        let resized = try resizeIfNeeded(data: outputData, contentType: effectiveType)
        let stripped =
            policy.stripImageLocation
            ? try stripGPS(data: resized, contentType: effectiveType)
            : resized

        let ext = effectiveType.preferredFilenameExtension ?? hint.preferredFilenameExtension ?? "bin"
        guard policy.isAllowedForUpload(effectiveType, ext) else {
            throw MaterializerError.disallowedContentType
        }

        let stem =
            suggestedName.flatMap(sanitizeStem)
            ?? "Photo-\(timestampedName(date: Date()))"
        let basename = allocateUnique(stem: stem, ext: ext)
        let destURL = parentDir.appendingPathComponent(basename)
        do {
            try stripped.write(to: destURL)
        } catch {
            throw MaterializerError.tempWriteFailed(error)
        }

        return MaterializedUpload(
            tempFileURL: destURL,
            params: MediaCreateParams(filePath: destURL.path),
            kind: .image,
            displayName: basename
        )
    }

    /// PHPicker video path. `loadFileRepresentation` hands us a
    /// provider-owned URL valid ONLY during the callback. Copy bytes into
    /// our parentDir inside the callback, then run the export from the
    /// owned copy.
    private func materializePhotoLibraryVideo(
        id: UUID,
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
                if let err { cont.resume(throwing: err); return }
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
                    cont.resume(throwing: MaterializerError.tempWriteFailed(error))
                }
            }
        }

        defer { try? FileManager.default.removeItem(at: copiedSource) }

        let asset = AVURLAsset(url: copiedSource)
        let duration = try await asset.load(.duration).seconds
        if let cap = policy.videoMaxDurationSeconds, duration > cap {
            throw MaterializerError.durationCapExceeded
        }

        let outputType = AVFileType(rawValue: policy.videoOutputContentType.identifier)
        let outputExt = policy.videoOutputContentType.preferredFilenameExtension ?? "mp4"
        let stem =
            suggestedName.flatMap(sanitizeStem)
            ?? "Video-\(timestampedName(date: Date()))"
        let basename = allocateUnique(stem: stem, ext: outputExt)
        let destURL = parentDir.appendingPathComponent(basename)

        guard policy.isAllowedForUpload(policy.videoOutputContentType, outputExt) else {
            throw MaterializerError.disallowedContentType
        }

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

    /// PHPicker GIF path. ImageIO's thumbnail/encode round-trip used by
    /// `resizeIfNeeded` and `stripGPS` would flatten animation to a single
    /// frame, so GIFs raw-copy bytes through the provider — matching V1's
    /// `ItemProviderMediaExporter.processGIF` and V2's `.file` GIF branch.
    private func materializePhotoLibraryGIF(
        id: UUID,
        parentDir: URL,
        itemProvider: NSItemProvider,
        suggestedName: String?
    ) async throws -> MaterializedUpload {
        guard policy.isAllowedForUpload(.gif, "gif") else {
            throw MaterializerError.disallowedContentType
        }

        let stem =
            suggestedName.flatMap(sanitizeStem)
            ?? "Photo-\(timestampedName(date: Date()))"
        let basename = allocateUnique(stem: stem, ext: "gif")
        let destURL = parentDir.appendingPathComponent(basename)

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            itemProvider.loadFileRepresentation(
                forTypeIdentifier: UTType.gif.identifier
            ) { providerURL, err in
                if let err { cont.resume(throwing: err); return }
                guard let providerURL else {
                    cont.resume(throwing: MaterializerError.fileNotFound); return
                }
                do {
                    try FileManager.default.copyItem(at: providerURL, to: destURL)
                    cont.resume()
                } catch {
                    cont.resume(throwing: MaterializerError.tempWriteFailed(error))
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
        id: UUID,
        parentDir: URL,
        image: UIImage,
        capturedAt: Date
    ) throws -> MaterializedUpload {
        guard let jpegData = image.jpegData(compressionQuality: CGFloat(policy.imageJpegQuality))
        else {
            throw MaterializerError.heicConversionFailed
        }
        let resized = try resizeIfNeeded(data: jpegData, contentType: .jpeg)
        let stripped =
            policy.stripImageLocation
            ? try stripGPS(data: resized, contentType: .jpeg)
            : resized

        guard policy.isAllowedForUpload(.jpeg, "jpg") else {
            throw MaterializerError.disallowedContentType
        }
        let basename = allocateUnique(stem: "IMG_\(timestampedName(date: capturedAt))", ext: "jpg")
        let destURL = parentDir.appendingPathComponent(basename)
        do { try stripped.write(to: destURL) } catch {
            throw MaterializerError.tempWriteFailed(error)
        }
        return MaterializedUpload(
            tempFileURL: destURL,
            params: MediaCreateParams(filePath: destURL.path),
            kind: .image,
            displayName: basename
        )
    }

    private func materializeCameraVideo(
        id: UUID,
        parentDir: URL,
        sourceURL: URL,
        capturedAt: Date,
        stageProgress: Progress
    ) async throws -> MaterializedUpload {
        let asset = AVURLAsset(url: sourceURL)
        let duration = try await asset.load(.duration).seconds
        if let cap = policy.videoMaxDurationSeconds, duration > cap {
            throw MaterializerError.durationCapExceeded
        }

        let outputType = AVFileType(rawValue: policy.videoOutputContentType.identifier)
        let ext = policy.videoOutputContentType.preferredFilenameExtension ?? "mp4"
        let basename = allocateUnique(stem: "IMG_\(timestampedName(date: capturedAt))", ext: ext)
        let destURL = parentDir.appendingPathComponent(basename)

        guard policy.isAllowedForUpload(policy.videoOutputContentType, ext) else {
            throw MaterializerError.disallowedContentType
        }

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

    /// iOS 17-compatible AVAssetExportSession via the callback API.
    ///
    /// Drives `stageProgress.completedUnitCount` from a sibling polling Task
    /// that samples `session.progress` every 100 ms. Cancellation is wired
    /// through `withTaskCancellationHandler { ... } onCancel: { session.cancelExport() }`.
    ///
    // TODO: when minimum deployment target moves to iOS 18+, replace this
    // with `session.export(to:as:)` async + `session.states(updateInterval:)`.
    // The async export observes Task.cancel() natively, and `states(...)`
    // yields Foundation.Progress instances ready to addChild without polling.
    private func exportVideo(
        asset: AVURLAsset,
        to destURL: URL,
        outputType: AVFileType,
        stageProgress: Progress
    ) async throws {
        guard
            let session = AVAssetExportSession(
                asset: asset,
                presetName: policy.videoExportPreset
            )
        else {
            throw MaterializerError.videoExportFailed(
                VideoExportFailureReason.noExporterForPreset
            )
        }
        session.outputURL = destURL
        session.outputFileType = outputType
        session.shouldOptimizeForNetworkUse = true

        // `AVAssetExportSession` isn't `Sendable`, but the poll task only
        // reads `.progress` and the cancel handler only calls `.cancelExport()`
        // — both safe to invoke off the original actor. Wrap in an unchecked
        // box so the @Sendable closures can capture it under Swift 6.
        let box = UnsafeSendableBox(session)
        let pollTask = Task { [stageProgress, box] in
            while !Task.isCancelled {
                stageProgress.completedUnitCount = Int64(
                    (Double(stageProgress.totalUnitCount) * Double(box.value.progress)).rounded()
                )
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        defer { pollTask.cancel() }

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                session.exportAsynchronously {
                    switch session.status {
                    case .completed:
                        cont.resume()
                    case .failed, .cancelled:
                        cont.resume(
                            throwing: MaterializerError.videoExportFailed(
                                session.error ?? VideoExportFailureReason.missingUnderlyingError
                            )
                        )
                    default:
                        cont.resume(
                            throwing: MaterializerError.videoExportFailed(
                                VideoExportFailureReason.unexpectedStatus(session.status)
                            )
                        )
                    }
                }
            }
        } onCancel: { [box] in
            box.value.cancelExport()
        }

        // Snap stageProgress to full — the final poll may have been just shy
        // of 1.0 when the continuation resumed.
        stageProgress.completedUnitCount = stageProgress.totalUnitCount
    }

    // MARK: - File

    private func materializeFile(
        id: UUID,
        parentDir: URL,
        sourceURL: URL,
        stageProgress: Progress
    ) async throws -> MaterializedUpload {
        guard securityScopedAccessor.start(sourceURL) else {
            throw MaterializerError.securityScopedAccessDenied
        }
        defer { securityScopedAccessor.stop(sourceURL) }

        let contentType = try resolveContentType(of: sourceURL)
        let stem =
            sanitizeStem(sourceURL.deletingPathExtension().lastPathComponent)
            ?? "File-\(timestampedName(date: Date()))"

        if contentType.conforms(to: .image) && contentType != .gif {
            return try materializeFileImage(
                id: id,
                parentDir: parentDir,
                sourceURL: sourceURL,
                contentType: contentType,
                stem: stem
            )
        }
        if contentType.conforms(to: .movie) {
            return try await materializeFileVideo(
                id: id,
                parentDir: parentDir,
                sourceURL: sourceURL,
                stem: stem,
                stageProgress: stageProgress
            )
        }
        return try materializeFileRawCopy(
            id: id,
            parentDir: parentDir,
            sourceURL: sourceURL,
            contentType: contentType,
            stem: stem
        )
    }

    func materializeFileImage(
        id: UUID,
        parentDir: URL,
        sourceURL: URL,
        contentType: UTType,
        stem: String
    ) throws -> MaterializedUpload {
        let data = try Data(contentsOf: sourceURL)
        let effectiveType: UTType
        let converted: Data
        if contentType == .heic && policy.convertHEICToJPEG {
            converted = try heicToJPEG(data: data)
            effectiveType = .jpeg
        } else {
            converted = data
            effectiveType = contentType
        }
        let resized = try resizeIfNeeded(data: converted, contentType: effectiveType)
        let stripped =
            policy.stripImageLocation
            ? try stripGPS(data: resized, contentType: effectiveType)
            : resized

        let ext = effectiveType.preferredFilenameExtension ?? sourceURL.pathExtension
        guard policy.isAllowedForUpload(effectiveType, ext) else {
            throw MaterializerError.disallowedContentType
        }
        let basename = allocateUnique(stem: stem, ext: ext)
        let destURL = parentDir.appendingPathComponent(basename)
        do {
            try stripped.write(to: destURL)
        } catch {
            throw MaterializerError.tempWriteFailed(error)
        }
        return MaterializedUpload(
            tempFileURL: destURL,
            params: MediaCreateParams(filePath: destURL.path),
            kind: .image,
            displayName: basename
        )
    }

    private func materializeFileVideo(
        id: UUID,
        parentDir: URL,
        sourceURL: URL,
        stem: String,
        stageProgress: Progress
    ) async throws -> MaterializedUpload {
        let asset = AVURLAsset(url: sourceURL)
        let duration = try await asset.load(.duration).seconds
        if let cap = policy.videoMaxDurationSeconds, duration > cap {
            throw MaterializerError.durationCapExceeded
        }
        let outputType = AVFileType(rawValue: policy.videoOutputContentType.identifier)
        let outputExt = policy.videoOutputContentType.preferredFilenameExtension ?? "mp4"
        guard policy.isAllowedForUpload(policy.videoOutputContentType, outputExt) else {
            throw MaterializerError.disallowedContentType
        }
        let basename = allocateUnique(stem: stem, ext: outputExt)
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

    private func materializeFileRawCopy(
        id: UUID,
        parentDir: URL,
        sourceURL: URL,
        contentType: UTType,
        stem: String
    ) throws -> MaterializedUpload {
        let ext = sourceURL.pathExtension.isEmpty ? "bin" : sourceURL.pathExtension
        guard policy.isAllowedForUpload(contentType, ext) else {
            throw MaterializerError.disallowedContentType
        }
        let basename = allocateUnique(stem: stem, ext: ext)
        let destURL = parentDir.appendingPathComponent(basename)
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
        } catch {
            throw MaterializerError.tempWriteFailed(error)
        }
        return MaterializedUpload(
            tempFileURL: destURL,
            params: MediaCreateParams(filePath: destURL.path),
            kind: kindFor(contentType: contentType),
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
                if let err { cont.resume(throwing: err); return }
                guard let data else {
                    cont.resume(throwing: MaterializerError.fileNotFound); return
                }
                cont.resume(returning: data)
            }
        }
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

    private func kindFor(contentType: UTType) -> MediaKind {
        if contentType.conforms(to: .image) { return .image }
        if contentType.conforms(to: .movie) { return .video }
        if contentType.conforms(to: .audio) { return .audio }
        return .document
    }

    private func sanitizeStem(_ name: String) -> String? {
        let cleaned =
            name
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\u{0}", with: "")
        let trimmed = String(cleaned.prefix(256))
        return trimmed.isEmpty ? nil : trimmed
    }

    private func allocateUnique(stem: String, ext: String) -> String {
        usedBasenames.withLock { used in
            let first = "\(stem).\(ext)"
            if used.insert(first).inserted {
                return first
            }
            var n = 2
            while true {
                let candidate = "\(stem) (\(n)).\(ext)"
                if used.insert(candidate).inserted {
                    return candidate
                }
                n += 1
            }
        }
    }

    private func timestampedName(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        return formatter.string(from: date)
    }
}
