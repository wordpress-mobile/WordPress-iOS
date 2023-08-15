import Foundation
import PhotosUI

final class ItemProviderMediaExporter: MediaExporter {
    var mediaDirectoryType: MediaDirectory = .uploads
    var imageOptions: MediaImageExporter.Options?
    var videoOptions: MediaVideoExporter.Options?
    var allowableFileExtensions = Set<String>()

    private let itemProvider: NSItemProvider

    init(itemProvider: NSItemProvider) {
        self.itemProvider = itemProvider
    }

    func export(onCompletion: @escaping (MediaExport) -> Void, onError: @escaping (MediaExportError) -> Void) -> Progress {
        let progress = Progress.discreteProgress(totalUnitCount: MediaExportProgressUnits.done)

        func processImage(at url: URL) throws {
            let exporter = MediaImageExporter(url: url)
            exporter.mediaDirectoryType = mediaDirectoryType
            if let imageOptions {
                exporter.options = imageOptions
                if imageOptions.exportImageType == nil, let type = itemProvider.registeredTypeIdentifiers.first {
                    exporter.options.exportImageType = preferedExportTypeFor(uti: type)
                }
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

        let loadProgress = itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.data.identifier) { url, error in
            guard let url else {
                onError(ExportError.underlyingError(error))
                return
            }
            do {
                // Retaining `self` on purpose.
                let copyURL = try self.mediaFileManager.makeLocalMediaURL(withFilename: url.lastPathComponent, fileExtension: url.pathExtension)
                try FileManager.default.copyItem(at: url, to: copyURL)
                if self.itemProvider.hasItemConformingToTypeIdentifier(UTType.gif.identifier) {
                    try processGIF(at: copyURL)
                } else if self.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    try processImage(at: copyURL)
                } else if self.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) ||
                            self.itemProvider.hasItemConformingToTypeIdentifier(UTType.video.identifier) {
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

    enum ExportError: MediaExportError {
        case underlyingError(Error?)

        #warning("implement proper error handling")
        var description: String {
            return "Something went wrong"
        }
    }
}
