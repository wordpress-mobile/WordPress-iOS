import UIKit
import AsyncImageKit

/// Media export handling assets from external sources i.e.: Stock Photos
///
class MediaExternalExporter: MediaExporter {

    public enum ExportError: MediaExportError {

        case downloadError(NSError)

        public var errorDescription: String? { description }

        public var description: String {
            switch self {
            case .downloadError(let error):
                return error.localizedDescription
            }
        }
    }

    var mediaDirectoryType: MediaDirectory = .uploads

    let asset: ExternalMediaAsset

    init(externalAsset: ExternalMediaAsset) {
        asset = externalAsset
    }

    /// Downloads and export the external media asset
    ///
    func export(onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        if asset.largeURL.isGif {
            return downloadGif(from: asset.largeURL, onCompletion: onCompletion, onError: onError)
        }

        Task {
            do {
                let options = ImageRequestOptions(isMemoryCacheEnabled: false)
                let image = try await ImageDownloader.shared.image(from: asset.largeURL, options: options)
                self.exportImage(image, onCompletion: onCompletion, onError: onError)
            } catch {
                onError(ExportError.downloadError(error as NSError))
            }
        }
        return Progress.discreteCompletedProgress()
    }

    private func downloadGif(from url: URL, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        Task {
            do {
                let options = ImageRequestOptions(isMemoryCacheEnabled: false)
                let data = try await ImageDownloader.shared.data(for: ImageRequest(url: url, options: options))
                self.gifDataDownloaded(data: data, fromURL: url, error: nil, onCompletion: onCompletion, onError: onError)
            } catch {
                onError(ExportError.downloadError(error as NSError))
            }
        }
        return Progress.discreteCompletedProgress()
    }

    /// Saves downloaded GIF data to the filesystem and exports it.
    ///
    private func gifDataDownloaded(data: Data, fromURL url: URL, error: Error?, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) {
        do {
            let mediaURL = try mediaFileManager.makeLocalMediaURL(withFilename: url.lastPathComponent,
                                                                  fileExtension: "gif")
            try data.write(to: mediaURL)
            onCompletion(MediaExport(url: mediaURL,
                                     fileSize: mediaURL.fileSize,
                                     width: mediaURL.pixelSize.width,
                                     height: mediaURL.pixelSize.height,
                                     duration: nil))
        } catch {
            onError(exporterErrorWith(error: error))
        }

        return
    }

    private func exportImage(_ image: UIImage, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) {
        let exporter = MediaImageExporter(image: image, filename: asset.name, caption: asset.caption)
        exporter.mediaDirectoryType = mediaDirectoryType

        exporter.export(onCompletion: onCompletion, onError: onError)
    }
}
