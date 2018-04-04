import Foundation

/// A media asset protocol used to export media from external sources
///
protocol MediaExternalAsset {

    /// The external URL
    var URL: URL { get }
    /// Asset name
    var name: String { get }
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

    /// Downloads and export de external media asset
    ///
    func export(onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        WPImageSource.shared().downloadImage(for: asset.URL, withSuccess: { (image) in
            self.exportImage(image, onCompletion: onCompletion, onError: onError)
        }) { (error) in
            let exportError = ExportError.downloadError(error as NSError)
            onError(exportError)
        }

        return Progress.discreteCompletedProgress()
    }

    private func exportImage(_ image: UIImage, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) {
        let exporter = MediaImageExporter(image: image, filename: asset.name)
        exporter.mediaDirectoryType = mediaDirectoryType
        exporter.export(onCompletion: onCompletion, onError: onError)
    }
}
