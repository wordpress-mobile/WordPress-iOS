import Foundation
import PhotosUI

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
            // If image format is not supported, switch to `.heic`.
            if exporter.options.exportImageType == nil,
                let type = provider.registeredTypeIdentifiers.first,
                !ItemProviderMediaExporter.supportedImageTypes.contains(type) {
                exporter.options.exportImageType = UTType.heic.identifier
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

        let loadProgress = provider.loadFileRepresentation(forTypeIdentifier: UTType.data.identifier) { url, error in
            guard let url else {
                onError(ExportError.underlyingError(error))
                return
            }
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
                    onError(ExportError.underlyingError(URLError(.unknown)))
                }
            } catch {
                onError(ExportError.underlyingError(error))
            }
        }
        progress.addChild(loadProgress, withPendingUnitCount: MediaExportProgressUnits.halfDone)
        return progress
    }

    #warning("should it be heif or heic?")

    /// The list of image formats supported by the backend.
    /// See https://wordpress.com/support/accepted-filetypes/.
    ///
    /// One notable format missing from the list is `.webp`, which is not supported
    /// by `CGImageDestinationCreateWithURL` and, in turn, `MediaImageExporter`.
    ///
    /// If the format is not supported, the app fallbacks to `.heic` which is
    /// similar to `.webp`: more efficient than traditional formats and supports
    /// opacity, unlike `.jpeg`.
    private static let supportedImageTypes: Set<String> = Set([
        UTType.png,
        UTType.jpeg,
        UTType.gif,
        UTType.heic,
        UTType.svg
    ].map(\.identifier))

    private func hasConformingType(_ type: UTType) -> Bool {
        provider.hasItemConformingToTypeIdentifier(type.identifier)
    }

    enum ExportError: MediaExportError {
        case underlyingError(Error?)

        #warning("implement proper error handling")
        var description: String {
            return "Something went wrong"
        }
    }
}
