import Foundation

/// A media asset protocol used to export media from external sources
///
protocol MediaExternalAsset {

    /// The external URL
    var URL: URL { get }
    /// Asset name
    var name: String { get }
    // Caption
    var caption: String { get }
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
        if asset.URL.isGif {
            return downloadGif(from: asset.URL, onCompletion: onCompletion, onError: onError)
        }

        WPImageSource.shared().downloadImage(for: asset.URL, withSuccess: { (image) in
            self.imageDownloaded(image: image, error: nil, onCompletion: onCompletion, onError: onError)
        }) { (error) in
            self.imageDownloaded(image: nil, error: error, onCompletion: onCompletion, onError: onError)
        }

        return Progress.discreteCompletedProgress()
    }

    /// Downloads an external GIF file, or uses one from the AnimatedImageCache.
    ///
    private func downloadGif(from url: URL, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        let request = URLRequest(url: url)
        let task = AnimatedImageCache.shared.animatedImage(request, placeholderImage: nil,
                                                           success: { (data, _) in
                                                            self.gifDataDownloaded(data: data,
                                                                                   fromURL: url,
                                                                                   error: nil,
                                                                                   onCompletion: onCompletion,
                                                                                   onError: onError)
        }, failure: { error in
            if let error = error {
                onError(self.exporterErrorWith(error: error))
            }
        })

        if #available(iOS 11.0, *) {
            return task?.progress ?? Progress.discreteCompletedProgress()
        } else {
            return Progress.discreteCompletedProgress()
        }
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
        let exporter = MediaImageExporter(image: image, filename: asset.name, caption: asset.caption)
        exporter.mediaDirectoryType = mediaDirectoryType

        exporter.export(onCompletion: onCompletion, onError: onError)
    }
}
