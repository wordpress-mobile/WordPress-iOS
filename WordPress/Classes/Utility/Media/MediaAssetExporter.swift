import Foundation
import MobileCoreServices

/// MediaLibrary export handling of PHAssets
///
class MediaAssetExporter: MediaExporter {

    var maximumImageSize: CGFloat?
    var stripsGeoLocationIfNeeded = false
    var mediaDirectoryType: MediaLibrary.MediaDirectory = .uploads

    /// Enumerable type value for an AssetExport, typed according to the resulting export of the asset.
    ///
    public enum AssetExport {
        case exportedImage(MediaImageExport)
        case exportedVideo(MediaVideoExport)
        case exportedGIF(MediaGIFExport)
    }

    public enum AssetExportError: MediaExportError {
        case unsupportedPHAssetMediaType
        case expectedPHAssetImageType
        case expectedPHAssetVideoType
        case expectedPHAssetGIFType
        case failedLoadingPHImageManagerRequest
        case unavailablePHAssetImageResource
        case unavailablePHAssetVideoResource
        case failedCreatingVideoExportSession
        case failedExportingVideoDuringExportSession

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
                 .failedCreatingVideoExportSession,
                 .failedExportingVideoDuringExportSession:
                return NSLocalizedString("The video could not be added to the Media Library.", comment: "Message shown when a video failed to load while trying to add it to the Media library.")
            case .expectedPHAssetGIFType:
                return NSLocalizedString("The GIF could not be added to the Media Library.", comment: "Message shown when a GIF failed to load while trying to add it to the Media library.")
            }
        }

        func toNSError() -> NSError {
            return NSError(domain: _domain, code: _code, userInfo: [NSLocalizedDescriptionKey: String(describing: self)])
        }
    }

    /// Helper method encapsulating exporting either an image or video.
    ///
    func exportData(forAsset asset: PHAsset, onCompletion: @escaping (AssetExport) -> Void, onError: @escaping (MediaExportError) -> Void) {
        if asset.mediaType == .image {
            exportImage(forAsset: asset, onCompletion: onCompletion, onError: onError)
        } else if asset.mediaType == .video {
            exportVideo(forAsset: asset, onCompletion: onCompletion, onError: onError)
        } else {
            onError(AssetExportError.unsupportedPHAssetMediaType)
        }
    }

    fileprivate func exportImage(forAsset asset: PHAsset, onCompletion: @escaping (AssetExport) -> Void, onError: @escaping (MediaExportError) -> Void) {
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
            if let maximumImageSize = maximumImageSize {
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
            let manager = PHImageManager.default()
            manager.requestImage(for: asset,
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
                                    exporter.maximumImageSize = self.maximumImageSize
                                    exporter.stripsGeoLocationIfNeeded = self.stripsGeoLocationIfNeeded
                                    exporter.mediaDirectoryType = self.mediaDirectoryType
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
    fileprivate func exportVideo(forAsset asset: PHAsset, onCompletion: @escaping (AssetExport) -> Void, onError: @escaping (MediaExportError) -> Void) {
        do {
            guard asset.mediaType == .video else {
                throw AssetExportError.expectedPHAssetVideoType
            }
            // Get the resource matching the type, to export.
            let resources = PHAssetResource.assetResources(for: asset).filter({ $0.type == .video })
            guard let videoResource = resources.first else {
                throw AssetExportError.unavailablePHAssetVideoResource
            }
            // Generate a new URL for the local Media.
            let exportURL = try MediaLibrary.makeLocalMediaURL(withFilename: videoResource.originalFilename,
                                                               fileExtension: nil,
                                                               type: mediaDirectoryType)
            // Configure an error handler for the export session.
            let onExportSessionError: (Error?) -> Void = { (error) in
                guard let error = error else {
                    onError(AssetExportError.failedCreatingVideoExportSession)
                    return
                }
                onError(self.exporterErrorWith(error: error))
            }
            // Configure a completion handler for the export session.
            let onExportSessionCompletion: (AVAssetExportSession) -> Void = { (session) in
                // Guard that the session completed, or return an error.
                guard session.status == .completed else {
                    if let error = session.error {
                        onError(self.exporterErrorWith(error: error))
                    } else {
                        onError(AssetExportError.failedExportingVideoDuringExportSession)
                    }
                    return
                }
                // Finally complete with the export URL.
                onCompletion(AssetExport.exportedVideo(MediaVideoExport(url: exportURL,
                                                                        fileSize: exportURL.resourceFileSize,
                                                                        duration: session.asset.duration.seconds)))
            }
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            let manager = PHImageManager.default()
            // Begin export by requesting an export session.
            manager.requestExportSession(forVideo: asset,
                                         options: options,
                                         exportPreset: AVAssetExportPresetHighestQuality,
                                         resultHandler: { (session, info) -> Void in
                                            guard let session = session else {
                                                onExportSessionError(info?[PHImageErrorKey] as? Error)
                                                return
                                            }
                                            // Configure the export session.
                                            session.shouldOptimizeForNetworkUse = true
                                            session.outputURL = exportURL
                                            session.outputFileType = videoResource.uniformTypeIdentifier
                                            // Trigger the export with the completion handler.
                                            session.exportAsynchronously {
                                                onExportSessionCompletion(session)
                                            }
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
    fileprivate func exportGIF(forAsset asset: PHAsset, resource: PHAssetResource, onCompletion: @escaping (AssetExport) -> Void, onError: @escaping (MediaExportError) -> Void) {
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
