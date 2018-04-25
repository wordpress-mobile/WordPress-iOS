import Foundation

/// A media asset protocol used to export media from external sources
///
protocol MediaExternalAsset {

    /// The external URL
    var URL: URL { get }
    /// Asset name
    var name: String { get }
}

enum MediaExternalExporterError: MediaExportError {

    case unknownError

    var description: String {
        switch self {
        case .unknownError:
            return NSLocalizedString("The item could not be added to the Media Library.", comment: "Message shown when an asset failed to load while trying to add it to the Media library.")
        }
    }
}

/// Media export handling assets from external sources i.e.: Stock Photos
///
class MediaExternalExporter: MediaExporter {

    public enum ExportError: MediaExportError {

        case downloadError(NSError)

        public var description: String {
            switch self {
            case .downloadError(let error):
                return error.localizedDescription
            }
        }
    }

    var mediaDirectoryType: MediaDirectory = .uploads

    let asset: MediaExternalAsset

    init(externalAsset: MediaExternalAsset) {
        asset = externalAsset
    }

    /// Downloads and export the external media asset
    ///
    func export(onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        WPImageSource.shared().downloadImage(for: asset.URL, withSuccess: { (image) in
            self.imageDownloaded(image: image, error: nil, onCompletion: onCompletion, onError: onError)
        }) { (error) in
            self.imageDownloaded(image: nil, error: error, onCompletion: onCompletion, onError: onError)
        }

        return Progress.discreteCompletedProgress()
    }

    /// Helper method to tackle the unlike posibility of both image and error being nil.
    /// This shouln't happen since both image and error are being guarded propertly in `WPImageSource`.
    /// `WPImageSource` needs better Swift compatibility.
    ///
    private func imageDownloaded(image: UIImage?, error: Error?, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) {
        if let image = image {
            exportImage(image, onCompletion: onCompletion, onError: onError)
        } else if let error = error {
            let exportError = ExportError.downloadError(error as NSError)
            onError(exportError)
        } else {
            onError(MediaExternalExporterError.unknownError)
        }
    }

    private func exportImage(_ image: UIImage, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) {
        let exporter = MediaImageExporter(image: image, filename: asset.name)
        exporter.mediaDirectoryType = mediaDirectoryType
        exporter.export(onCompletion: onCompletion, onError: onError)
    }
}
