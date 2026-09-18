import Foundation
import PhotosUI
import WordPressData
import WordPressShared

/// Manages export of media assets: images and video.
final class ItemProviderMediaExporter: MediaExporter {
    var mediaDirectoryType: MediaDirectory = .uploads
    var imageOptions: MediaImageExporter.Options?
    var videoOptions: MediaVideoExporter.Options?

    /// `nil` for an item picked with the legacy picker under Lockdown Mode, which vends
    /// assets rather than providers — that route reads the file from the photo library.
    private let provider: NSItemProvider?
    private let assetIdentifier: String?

    /// Whether to read the file straight from the photo library instead of asking the
    /// item provider for it.
    ///
    /// Defaults to Lockdown Mode, where the system's file provider extension can't
    /// materialize large photos at all (see `handleLoadFailure` and
    /// `PhotoLibraryFileLoader`). Everywhere else the provider is faster and needs no
    /// Photos authorization, so it stays the default route.
    ///
    /// The two routes are exclusive: once this picks the photo library, a failure there
    /// is reported rather than retried through the provider, which in Lockdown Mode is
    /// the thing that doesn't work.
    var prefersPhotoLibrarySource = LockdownHelper.isDeviceLockdownModeEnabled

    /// - parameter assetIdentifier: The local identifier of the `PHAsset` the item was
    ///   picked from, when the picker was library-backed. See `PhotosPickerAsset`.
    init(provider: NSItemProvider?, assetIdentifier: String? = nil) {
        self.provider = provider
        self.assetIdentifier = assetIdentifier
    }

    func export(onCompletion originalOnCompletion: @escaping (MediaExport) -> Void, onError originalOnError: @escaping (MediaExportError) -> Void) -> Progress {
        let progress = Progress.discreteProgress(totalUnitCount: MediaExportProgressUnits.done)
        let onCompletion: (MediaExport) -> Void
        let onError: (MediaExportError) -> Void

        // Create a temporary directory to stage the picked file, whether it came from the
        // `NSItemProvider` instance or straight from the photo library.
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            // Delete the temporary directory after we are done with the exported file.
            onCompletion = {
                try? FileManager.default.removeItem(at: tempDir)
                originalOnCompletion($0)
            }
            onError = {
                try? FileManager.default.removeItem(at: tempDir)
                originalOnError($0)
            }
        } catch {
            originalOnError(MediaExportSystemError.failedWith(systemError: error))
            return progress
        }

        // It's important to use the `MediaImageExporter` because it strips the
        // GPS data and performs other image manipulations before the upload.
        func processImage(at url: URL, typeIdentifier: String?) throws {
            let exporter = MediaImageExporter(url: url)
            exporter.mediaDirectoryType = mediaDirectoryType
            if let imageOptions {
                exporter.options = imageOptions
            }
            // If image format is not supported, switch to `.jpeg`.
            if exporter.options.exportImageType == nil,
               let type = typeIdentifier,
               !ItemProviderMediaExporter.supportedImageTypes.contains(type) {
                exporter.options.exportImageType = UTType.jpeg.identifier
            }
            let exportProgress = exporter.export(onCompletion: onCompletion, onError: onError)
            progress.addChild(exportProgress, withPendingUnitCount: MediaExportProgressUnits.halfDone)
        }

        // `MediaImageExporter` doesn't support GIF, so it requires special handling.
        func processGIF(at original: URL) throws {
            let url = try self.mediaFileManager.makeLocalMediaURL(withFilename: original.lastPathComponent, fileExtension: original.pathExtension)
            try FileManager.default.copyItem(at: original, to: url)

            let pixelSize = url.pixelSize
            let media = MediaExport(url: url, fileSize: url.fileSize, width: pixelSize.width, height: pixelSize.height, duration: nil)
            let exportProgress = Progress(totalUnitCount: 1)
            exportProgress.completedUnitCount = 1
            progress.addChild(exportProgress, withPendingUnitCount: MediaExportProgressUnits.halfDone)
            onCompletion(media)
        }

        func processVideo(at url: URL) throws {
            let exporter = MediaVideoExporter(url: url)
            exporter.mediaDirectoryType = mediaDirectoryType
            if let videoOptions {
                exporter.options = videoOptions
            }
            let exportProgress = exporter.export(onCompletion: onCompletion, onError: onError)
            progress.addChild(exportProgress, withPendingUnitCount: MediaExportProgressUnits.halfDone)
        }

        // The "process" functions are responsible for making sure the end result file
        // (the one passed to `onCompletion` block) is located in the local Media library dir (`mediaFileManager`).
        //
        // `resourceTypeIdentifier` is the type of a file streamed from the photo library.
        // It's `nil` for a file that came from the item provider, whose own registered
        // types describe it instead.
        func process(fileAt url: URL, resourceTypeIdentifier: String?) throws {
            let resourceType = resourceTypeIdentifier.flatMap(UTType.init)
            func hasType(_ type: UTType) -> Bool {
                resourceType.map { $0.conforms(to: type) } ?? self.hasConformingType(type)
            }
            if hasType(.gif) {
                try processGIF(at: url)
            } else if hasType(.image) {
                try processImage(at: url, typeIdentifier: resourceTypeIdentifier ?? self.provider?.registeredTypeIdentifiers.first)
            } else if hasType(.movie) || hasType(.video) {
                try processVideo(at: url)
            } else {
                onError(ExportError.unsupportedContentType)
            }
        }

        if prefersPhotoLibrarySource, let assetIdentifier {
            let loadProgress = Progress.discreteProgress(totalUnitCount: MediaExportProgressUnits.done)
            do {
                // Retaining `self` on purpose.
                try PhotoLibraryFileLoader.loadFile(assetIdentifier: assetIdentifier, into: tempDir, progress: loadProgress) { result in
                    switch result {
                    case .success(let file):
                        do {
                            try process(fileAt: file.url, resourceTypeIdentifier: file.typeIdentifier)
                        } catch {
                            onError(ExportError.underlyingError(error))
                        }
                    case .failure(let error):
                        // A cancelled upload is reported by the upload coordinator, so
                        // surfacing it here would show a spurious failure. Clean up the
                        // partially streamed file that `onError` would have removed.
                        guard !loadProgress.isCancelled else {
                            try? FileManager.default.removeItem(at: tempDir)
                            return
                        }
                        self.handlePhotoLibraryFailure(error, onError: onError)
                    }
                }
                progress.addChild(loadProgress, withPendingUnitCount: MediaExportProgressUnits.halfDone)
            } catch {
                // No fallback: under Lockdown Mode the item provider is precisely what
                // can't serve the file, so retrying through it would trade a clear
                // failure for a silent one.
                handlePhotoLibraryFailure(error, onError: onError)
            }
            return progress
        }

        guard let provider else {
            onError(ItemProviderMediaExporter.itemUnavailableError)
            return progress
        }

        let start = CFAbsoluteTimeGetCurrent()
        DDLogInfo("Will export file for provider: \(ObjectIdentifier(provider)) \(provider.registeredTypeIdentifiers)")

        let loadProgress = provider.loadFileRepresentation(forTypeIdentifier: UTType.data.identifier) { url, error in
            guard let url else {
                self.handleLoadFailure(error, onError: onError)
                return
            }
            let diff = CFAbsoluteTimeGetCurrent() - start
            DDLogInfo("Loaded file representation for provider: \(ObjectIdentifier(provider)) \(provider.registeredTypeIdentifiers) (\(diff) seconds)")

            // Retaining `self` on purpose.
            do {
                let copyURL = tempDir.appendingPathComponent(url.lastPathComponent)
                try FileManager.default.copyItem(at: url, to: copyURL)
                try process(fileAt: copyURL, resourceTypeIdentifier: nil)
            } catch {
                onError(ExportError.underlyingError(error))
            }
        }
        progress.addChild(loadProgress, withPendingUnitCount: MediaExportProgressUnits.halfDone)
        return progress
    }

    /// The list of image formats supported by the backend.
    /// See https://wordpress.com/support/accepted-filetypes/.
    ///
    /// One notable format missing from the list is `.webp`, which is not supported
    /// by `CGImageDestinationCreateWithURL` and, in turn, `MediaImageExporter`.
    /// If the format is not supported, the app falls back to `.jpeg`.
    ///
    /// Despire wp.com supporting `.heic`, self-hosted sites don't (yet),
    /// so, just to be safe, the app converts them to `.jpeg`. This should be
    /// revisited in the future as hopefully `.heic` support is added.
    private static let supportedImageTypes: Set<String> = Set([
        UTType.png,
        UTType.jpeg,
        UTType.gif,
        UTType.svg
    ].map(\.identifier))

    private func hasConformingType(_ type: UTType) -> Bool {
        provider?.hasItemConformingToTypeIdentifier(type.identifier) ?? false
    }

    /// Surfaces a failure to load the picked file from the `NSItemProvider`.
    ///
    /// When the provider's connection died (an XPC failure), the app shows a friendly
    /// message — specific to Lockdown Mode when it's enabled — and tracks the event so
    /// this case can be told apart from ordinary load failures. Any other error is
    /// surfaced as-is.
    ///
    /// A cancelled load (the user cancelled the upload, or the system cancelled the
    /// request) is *not* surfaced — cancellation is reported separately by the upload
    /// coordinator, so calling `onError` here would show a spurious failure.
    ///
    /// Observed only with iOS Lockdown Mode enabled: materializing a large photo
    /// (e.g. 36 MP) fails and the `PhotosFileProvider` process is killed, giving
    /// `NSItemProviderError -1000` over `NSCocoaErrorDomain 4099`.
    private func handleLoadFailure(_ error: Error?, onError: (MediaExportError) -> Void) {
        let providerID = provider.map(ObjectIdentifier.init).map(String.init(describing:)) ?? "none"
        guard let error else {
            DDLogError("Failed to load file representation for provider: \(providerID), error: nil")
            onError(ExportError.unknown)
            return
        }
        // A cancelled load isn't a failure to report: the upload coordinator cancels
        // this request's `Progress` (which fires this completion with a cancellation
        // error) and surfaces the cancellation itself. Bail out without calling
        // `onError` so we don't show a spurious "failed" message.
        if ItemProviderMediaExporter.isCancellation(error) {
            DDLogInfo("Cancelled loading file representation for provider: \(providerID)")
            return
        }
        DDLogError("Failed to load file representation for provider: \(providerID), error: \(error)")
        if let connectionError = ItemProviderMediaExporter.providerConnectionError(in: error) {
            let properties = providerErrorProperties(for: error, connectionError: connectionError)
            WPAnalytics.track(.mediaImportItemUnavailable, properties: properties)
            onError(ItemProviderMediaExporter.itemUnavailableError)
        } else {
            onError(ExportError.underlyingError(error))
        }
    }

    /// Surfaces a failure to read the picked file straight from the photo library —
    /// either the asset couldn't be resolved or streaming it failed.
    ///
    /// That route is only taken under Lockdown Mode (see `PhotoLibraryFileLoader`), where
    /// the item provider is precisely what can't serve the file — so there is nothing
    /// left to fall back to and the failure is reported to the user. It's tracked under
    /// the same event as a provider failure, told apart by `source`.
    private func handlePhotoLibraryFailure(_ error: Error, onError: (MediaExportError) -> Void) {
        DDLogError("Failed to read the picked asset from the photo library, error: \(error)")
        let error = error as NSError
        var properties = ItemProviderMediaExporter.lockdownProperties
        properties["source"] = "photo_library"
        properties["error_domain"] = error.domain
        properties["error_code"] = error.code
        properties["type_identifiers"] = typeIdentifiersDescription
        WPAnalytics.track(.mediaImportItemUnavailable, properties: properties)
        onError(ItemProviderMediaExporter.itemUnavailableError)
    }

    private func providerErrorProperties(for error: Error, connectionError: NSError) -> [AnyHashable: Any] {
        let error = error as NSError
        var properties = ItemProviderMediaExporter.lockdownProperties
        properties["source"] = "item_provider"
        properties["error_domain"] = error.domain
        properties["error_code"] = error.code
        properties["underlying_error_domain"] = connectionError.domain
        properties["underlying_error_code"] = connectionError.code
        properties["type_identifiers"] = typeIdentifiersDescription
        return properties
    }

    private var typeIdentifiersDescription: String {
        provider?.registeredTypeIdentifiers.joined(separator: ", ") ?? ""
    }

    /// The Lockdown Mode state recorded alongside an import failure. The device-wide flag
    /// is the one that governs `PhotosFileProvider`; the per-app value is secondary.
    private static var lockdownProperties: [AnyHashable: Any] {
        let device = LockdownHelper.isDeviceLockdownModeEnabled
        return [
            "lockdown_mode": device,
            "lockdown_mode_app_excluded": device && !LockdownHelper.isAppLockdownModeEnabled
        ]
    }

    /// The message shown when the app can't get the picked file from either route.
    private static var itemUnavailableError: ExportError {
        LockdownHelper.isDeviceLockdownModeEnabled ? .lockdownModeRestricted : .cannotLoadItem
    }

    /// The XPC connection error codes (in `NSCocoaErrorDomain`) that signal the item
    /// provider's process died while producing the file.
    private static let xpcConnectionErrorCodes: Set<Int> = [
        CocoaError.Code.xpcConnectionInterrupted.rawValue,
        CocoaError.Code.xpcConnectionInvalid.rawValue,
        CocoaError.Code.xpcConnectionReplyInvalid.rawValue
    ]

    /// Returns the first XPC connection error found in `error` or any of its
    /// underlying errors, or `nil` if there is none.
    static func providerConnectionError(in error: Error) -> NSError? {
        errorChain(from: error)
            .map { $0 as NSError }
            .first { $0.domain == NSCocoaErrorDomain && xpcConnectionErrorCodes.contains($0.code) }
    }

    /// Returns `true` when `error`, or any error it wraps, represents a cancellation
    /// rather than a genuine failure — a `CancellationError`, `NSUserCancelledError`,
    /// or `NSURLErrorCancelled`.
    static func isCancellation(_ error: Error) -> Bool {
        errorChain(from: error).contains { element in
            if element is CancellationError {
                return true
            }
            let nsError = element as NSError
            switch (nsError.domain, nsError.code) {
            case (NSCocoaErrorDomain, NSUserCancelledError),
                 (NSURLErrorDomain, NSURLErrorCancelled):
                return true
            default:
                return false
            }
        }
    }

    /// Flattens `error` and its underlying errors into a single list, bounded to guard
    /// against pathological cycles.
    ///
    /// `NSError.underlyingErrors` already surfaces the value stored under the legacy
    /// `NSUnderlyingErrorKey` (along with `NSMultipleUnderlyingErrorsKey`), so it is the
    /// only source we enqueue. Reading `NSUnderlyingErrorKey` separately as well would
    /// visit every wrapped error twice and halve the depth reachable before the bound.
    private static func errorChain(from error: Error) -> [Error] {
        var result: [Error] = []
        var queue: [Error] = [error]
        while let next = queue.first, result.count < 16 {
            queue.removeFirst()
            result.append(next)
            queue.append(contentsOf: (next as NSError).underlyingErrors)
        }
        return result
    }

    enum ExportError: MediaExportError {
        case unsupportedContentType
        case cannotLoadItem
        case lockdownModeRestricted
        case underlyingError(Error)
        case unknown

        public var errorDescription: String? { description }

        var description: String {
            switch self {
            case .unsupportedContentType:
                return NSLocalizedString("mediaExporter.error.unsupportedContentType", value: "Unsupported content type", comment: "An error message the app shows if media import fails")
            case .cannotLoadItem:
                return NSLocalizedString("mediaExporter.error.cannotLoadItem", value: "This item could not be added to the Media library. It may be too large to import. Please try again or resize the media.", comment: "Error shown when a selected photo or video can't be loaded from the device for upload.")
            case .lockdownModeRestricted:
                return NSLocalizedString("mediaExporter.error.lockdownMode", value: "This item can’t be added to the Media library while Lockdown Mode is on.", comment: "Error shown when a selected photo or video can't be imported because iOS Lockdown Mode is enabled.")
            case .underlyingError(let error):
                return error.localizedDescription
            case .unknown:
                return NSLocalizedString("mediaExporter.error.unknown", value: "The item could not be added to the Media library", comment: "An error message the app shows if media import fails")
            }
        }
    }
}
