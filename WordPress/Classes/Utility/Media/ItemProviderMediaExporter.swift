import Foundation
import PhotosUI

final class ItemProviderMediaExporter: MediaExporter {
    var mediaDirectoryType: MediaDirectory = .uploads
    var imageOptions: MediaImageExporter.Options?
    var videoOptions: MediaVideoExporter.Options?
    var allowableFileExtensions = Set<String>()

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
            do {
                // Retaining `self` on purpose.
                let copyURL = try self.mediaFileManager.makeLocalMediaURL(withFilename: url.lastPathComponent, fileExtension: url.pathExtension)
                try FileManager.default.copyItem(at: url, to: copyURL)
                if self.provider.hasItemConformingToTypeIdentifier(UTType.gif.identifier) {
                    try processGIF(at: copyURL)
                } else if self.provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    try processImage(at: copyURL)
                } else if self.provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) ||
                            self.provider.hasItemConformingToTypeIdentifier(UTType.video.identifier) {
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

#warning("make sure this works and handles image types that ImageIO doesn't support for encoding, e.g. webp")
#warning("update to support https://wordpress.com/support/accepted-filetypes/")
    private func preferedExportTypeFor(uti: String) -> String? {
        guard !allowableFileExtensions.isEmpty,
              let extensionType = UTType(uti)?.preferredFilenameExtension else {
            return nil
        }
        if allowableFileExtensions.contains(extensionType) {
            return uti
        } else {
            return UTType.jpeg.identifier
        }
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

    enum ExportError: MediaExportError {
        case underlyingError(Error?)

        #warning("implement proper error handling")
        var description: String {
            return "Something went wrong"
        }
    }
}
