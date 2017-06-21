import Foundation
import MobileCoreServices

/// MediaLibrary export handling of PHAssets
///
class MediaAssetExporter: MediaExporter {

    var mediaDirectoryType: MediaLibrary.MediaDirectory = .uploads

    var imageOptions: MediaImageExporter.Options?
    var videoOptions: MediaVideoExporter.Options?

    /// Enumerable type value for an AssetExport, typed according to the resulting export of the asset.
    ///
    public enum AssetExport {
        case exportedImage(MediaImageExport)
        case exportedVideo(MediaVideoExport)
        case exportedGIF(MediaGIFExport)
    }

    /// Completion block with an AssetExport.
    ///
    typealias OnAssetExport = (AssetExport) -> Void

    public enum AssetExportError: MediaExportError {
        case unsupportedPHAssetMediaType
        case expectedPHAssetImageType
        case expectedPHAssetVideoType
        case expectedPHAssetGIFType
        case failedLoadingPHImageManagerRequest
        case unavailablePHAssetImageResource
        case unavailablePHAssetVideoResource
        case failedRequestingVideoExportSession

        var description: String {
            switch self {
            case .unsupportedPHAssetMediaType:
                return NSLocalizedString("The item could not be added to the Media Library.", comment: "Message shown when an asset failed to load while trying to add it to the Media library.")
            case .expectedPHAssetImageType,
                 .failedLoadingPHImageManagerRequest,
                 .unavailablePHAssetImageResource:
                return NSLocalizedString("The image could not be added to the Media Library.", comment: "Message shown when an image failed to load while trying to add it to the Media library.")
            case .expectedPHAssetVideoType,
                 .unavailablePHAssetVideoResource,
                 .failedRequestingVideoExportSession:
                return NSLocalizedString("The video could not be added to the Media Library.", comment: "Message shown when a video failed to load while trying to add it to the Media library.")
            case .expectedPHAssetGIFType:
                return NSLocalizedString("The GIF could not be added to the Media Library.", comment: "Message shown when a GIF failed to load while trying to add it to the Media library.")
            }
        }
    }

    /// Default shared instance of the PHImageManager
    ///
    fileprivate lazy var imageManager = {
        return PHImageManager.default()
    }()

    /// Helper method encapsulating exporting either an image or video.
    ///
    func exportData(forAsset asset: PHAsset, onCompletion: @escaping OnAssetExport, onError: @escaping OnExportError) {
        switch asset.mediaType {
        case .image:
            exportImage(forAsset: asset, onCompletion: onCompletion, onError: onError)
        case .video:
            exportVideo(forAsset: asset, onCompletion: onCompletion, onError: onError)
        default:
            onError(AssetExportError.unsupportedPHAssetMediaType)
        }
    }

    fileprivate func exportImage(forAsset asset: PHAsset, onCompletion: @escaping OnAssetExport, onError: @escaping (MediaExportError) -> Void) {
        do {
            guard asset.mediaType == .image else {
                throw AssetExportError.expectedPHAssetImageType
            }

            // Get the resource matching the type, to export.
            let resources = PHAssetResource.assetResources(for: asset).filter({ $0.type == .photo })
            guard let resource = resources.first else {
                throw AssetExportError.unavailablePHAssetImageResource
            }

            if UTTypeEqual(resource.uniformTypeIdentifier as CFString, kUTTypeGIF) {
                // Since this is a GIF, handle the export in it's own way.
                exportGIF(forAsset: asset, resource: resource, onCompletion: onCompletion, onError: onError)
                return
            }

            // Configure the options for requesting the image.
            let options = PHImageRequestOptions()
            options.version = .current
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            options.isNetworkAccessAllowed = true

            // Configure the targetSize for PHImageManager to resize to.
            let targetSize: CGSize
            if let options = self.imageOptions, let maximumImageSize = options.maximumImageSize {
                targetSize = CGSize(width: maximumImageSize, height: maximumImageSize)
            } else {
                targetSize = PHImageManagerMaximumSize
            }

            // Configure an error handler for the image request.
            let onImageRequestError: (Error?) -> Void = { (error) in
                guard let error = error else {
                    onError(AssetExportError.failedLoadingPHImageManagerRequest)
                    return
                }
                onError(self.exporterErrorWith(error: error))
            }

            // Request the image.
            imageManager.requestImage(for: asset,
                                 targetSize: targetSize,
                                 contentMode: .aspectFit,
                                 options: options,
                                 resultHandler: { (image, info) in
                                    guard let image = image else {
                                        onImageRequestError(info?[PHImageErrorKey] as? Error)
                                        return
                                    }
                                    // Hand off the image export to a shared image writer.
                                    let exporter = MediaImageExporter()
                                    exporter.mediaDirectoryType = self.mediaDirectoryType
                                    if let options = self.imageOptions {
                                        exporter.options = options
                                    }
                                    exporter.exportImage(image,
                                                         fileName: resource.originalFilename,
                                                         onCompletion: { (imageExport) in
                                                            onCompletion(AssetExport.exportedImage(imageExport))
                                    },
                                                         onError: onError)
            })
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Exports and writes an asset's video data to a local Media URL.
    ///
    /// - parameter onCompletion: Called on successful export, with the local file URL of the exported asset.
    /// - parameter onError: Called if an error was encountered during export.
    ///
    fileprivate func exportVideo(forAsset asset: PHAsset, onCompletion: @escaping OnAssetExport, onError: @escaping OnExportError) {
        do {
            guard asset.mediaType == .video else {
                throw AssetExportError.expectedPHAssetVideoType
            }
            // Get the resource matching the type, to export.
            let resources = PHAssetResource.assetResources(for: asset).filter({ $0.type == .video })
            guard let videoResource = resources.first else {
                throw AssetExportError.unavailablePHAssetVideoResource
            }

            // Configure a video exporter to handle an export session.
            let videoExporter = MediaVideoExporter()
            videoExporter.mediaDirectoryType = mediaDirectoryType

            if let options = videoOptions {
                videoExporter.options = options
            }
            if videoExporter.options.preferredExportVideoType == nil {
                videoExporter.options.preferredExportVideoType = videoResource.uniformTypeIdentifier
            }
            let originalFilename = videoResource.originalFilename

            // Request an export session, which may take time to download the complete video data.
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            imageManager.requestExportSession(forVideo: asset,
                                              options: options,
                                              exportPreset: videoExporter.options.exportPreset,
                                              resultHandler: { (session, info) -> Void in
                                                guard let session = session else {
                                                    if let error = info?[PHImageErrorKey] as? Error {
                                                        onError(self.exporterErrorWith(error: error))
                                                    } else {
                                                        onError(AssetExportError.failedRequestingVideoExportSession)
                                                    }
                                                    return
                                                }
                                                videoExporter.exportVideo(with: session,
                                                                          filename: originalFilename,
                                                                          onCompletion: { (videoExport) in
                                                                            onCompletion(AssetExport.exportedVideo(videoExport))
                                                },
                                                                          onError: onError)
            })
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Exports and writes an asset's GIF data to a local Media URL.
    ///
    /// - parameter onCompletion: Called on successful export, with the local file URL of the exported asset.
    /// - parameter onError: Called if an error was encountered during export.
    ///
    fileprivate func exportGIF(forAsset asset: PHAsset, resource: PHAssetResource, onCompletion: @escaping OnAssetExport, onError: @escaping OnExportError) {
        do {
            guard UTTypeEqual(resource.uniformTypeIdentifier as CFString, kUTTypeGIF) else {
                throw AssetExportError.expectedPHAssetGIFType
            }
            let url = try MediaLibrary.makeLocalMediaURL(withFilename: resource.originalFilename,
                                                         fileExtension: "gif",
                                                         type: mediaDirectoryType)
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            let manager = PHAssetResourceManager.default()
            manager.writeData(for: resource,
                              toFile: url,
                              options: options,
                              completionHandler: { (error) in
                                if let error = error {
                                    onError(self.exporterErrorWith(error: error))
                                    return
                                }
                                onCompletion(AssetExport.exportedGIF(MediaGIFExport(url: url,
                                                                                    fileSize: url.resourceFileSize)))
            })
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }
}
