import Foundation
import PhotosUI

/// Manages export of media assets: images and video.
final class ItemProviderMediaExporter: MediaExporter {
    var mediaDirectoryType: MediaDirectory = .uploads
    var imageOptions: MediaImageExporter.Options?
    var videoOptions: MediaVideoExporter.Options?

    private let provider: NSItemProvider

    init(provider: NSItemProvider) {
        self.provider = provider
    }

    func export(onCompletion: @escaping (MediaExport) -> Void, onError: @escaping (MediaExportError) -> Void) -> Progress {
        let progress = Progress.discreteProgress(totalUnitCount: MediaExportProgressUnits.done)

        // It's important to use the `MediaImageExporter` because it strips the
        // GPS data and performs other image manipulations before the upload.
        func processImage(at url: URL) throws {
            let exporter = MediaImageExporter(url: url)
            exporter.mediaDirectoryType = mediaDirectoryType
            if let imageOptions {
                exporter.options = imageOptions
            }
            // If image format is not supported, switch to `.jpeg`.
            if exporter.options.exportImageType == nil,
               let type = provider.registeredTypeIdentifiers.first,
               !ItemProviderMediaExporter.supportedImageTypes.contains(type) {
                exporter.options.exportImageType = UTType.jpeg.identifier
            }
            let exportProgress = exporter.export(onCompletion: onCompletion, onError: onError)
            progress.addChild(exportProgress, withPendingUnitCount: MediaExportProgressUnits.halfDone)
        }

        // `MediaImageExporter` doesn't support GIF, so it requires special handling.
        func processGIF(at url: URL) throws {
            let pixelSize = url.pixelSize
            let media = MediaExport(url: url, fileSize: url.fileSize, width: pixelSize.width, height: pixelSize.height, duration: nil)
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

        let start = CFAbsoluteTimeGetCurrent()
        DDLogInfo("Will export file for provider: \(ObjectIdentifier(provider)) \(provider.registeredTypeIdentifiers)")

        let loadProgress = provider.loadFileRepresentation(forTypeIdentifier: UTType.data.identifier) { url, error in
            guard let url else {
                DDLogDebug("Loaded file representation for provider: \(ObjectIdentifier(self.provider)), error: \(String(describing: error)))")
                return
            }
            let diff = CFAbsoluteTimeGetCurrent() - start
            DDLogInfo("Loaded file representation for provider: \(ObjectIdentifier(self.provider)) \(self.provider.registeredTypeIdentifiers) (\(diff) seconds)")

            // Retaining `self` on purpose.
            do {
                let copyURL = try self.mediaFileManager.makeLocalMediaURL(withFilename: url.lastPathComponent, fileExtension: url.pathExtension)
                try FileManager.default.copyItem(at: url, to: copyURL)

                if self.hasConformingType(.gif) {
                    try processGIF(at: copyURL)
                } else if self.hasConformingType(.image) {
                    try processImage(at: copyURL)
                } else if self.hasConformingType(.movie) || self.hasConformingType(.video) {
                    try processVideo(at: copyURL)
                } else {
                    onError(ExportError.unsupportedContentType)
                }
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
        provider.hasItemConformingToTypeIdentifier(type.identifier)
    }

    enum ExportError: MediaExportError {
        case unsupportedContentType
        case underlyingError(Error?)

        public var errorDescription: String? { description }

        var description: String {
            switch self {
            case .unsupportedContentType:
                return NSLocalizedString("mediaExporter.error.unsupportedContentType", value: "Unsupported content type", comment: "An error message the app shows if media import fails")
            case .underlyingError(let error):
                return error?.localizedDescription ?? NSLocalizedString("mediaExporter.error.unknown", value: "The item could not be added to the Media library", comment: "An error message the app shows if media import fails")
            }
        }
    }
}
