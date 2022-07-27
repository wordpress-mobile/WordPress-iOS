import Foundation
import MobileCoreServices
import AVFoundation

/// Media export handling of PHAssets
///
class MediaAssetExporter: MediaExporter {

    var mediaDirectoryType: MediaDirectory = .uploads

    var imageOptions: MediaImageExporter.Options?
    var videoOptions: MediaVideoExporter.Options?

    var allowableFileExtensions = Set<String>()

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

    let asset: PHAsset

    init(asset: PHAsset) {
        self.asset = asset
    }

    @discardableResult public func export(onCompletion: @escaping OnMediaExport, onError: @escaping (MediaExportError) -> Void) -> Progress {
        switch asset.mediaType {
        case .image:
            return exportImage(forAsset: asset, onCompletion: onCompletion, onError: onError)
        case .video:
            return exportVideo(forAsset: asset, onCompletion: onCompletion, onError: onError)
        default:
            onError(AssetExportError.unsupportedPHAssetMediaType)
        }
        return Progress.discreteCompletedProgress()
    }

    @discardableResult fileprivate func exportImage(forAsset asset: PHAsset, onCompletion: @escaping OnMediaExport, onError: @escaping (MediaExportError) -> Void) -> Progress {

        guard asset.mediaType == .image else {
            onError(exporterErrorWith(error: AssetExportError.expectedPHAssetImageType))
            return Progress.discreteCompletedProgress()
        }
        var filename = UUID().uuidString + ".jpg"
        var resourceAvailableLocally = false
        // Get the resource matching the type, to export.
        let resources = PHAssetResource.assetResources(for: asset).filter({ $0.type == .photo })
        if let resource = resources.first {
            resourceAvailableLocally = true
            filename = resource.originalFilename
            if UTTypeEqual(resource.uniformTypeIdentifier as CFString, kUTTypeGIF) {
                // Since this is a GIF, handle the export in it's own way.
                return exportGIF(forAsset: asset, resource: resource, onCompletion: onCompletion, onError: onError)
            }
        }

        // Configure the options for requesting the image.
        let options = PHImageRequestOptions()
        options.version = .current
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        // If we have a resource object that means we have a local copy of the asset so we can request the image in sync mode.
        options.isSynchronous = resourceAvailableLocally
        let progress = Progress.discreteProgress(totalUnitCount: MediaExportProgressUnits.done)
        progress.isCancellable = true
        options.progressHandler = { (progressValue, error, stop, info) in
            progress.completedUnitCount = Int64(progressValue * Double(MediaExportProgressUnits.halfDone))
            if progress.isCancelled {
                stop.pointee = true
            }
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
        imageManager.requestImageDataAndOrientation(for: asset,
                             options: options,
                             resultHandler: { (data, uti, orientation, info) in
                                progress.completedUnitCount = MediaExportProgressUnits.halfDone
                                guard let imageData = data else {
                                    onImageRequestError(info?[PHImageErrorKey] as? Error)
                                    return
                                }
                                // Hand off the image export to a shared image writer.
                                let exporter = MediaImageExporter(data: imageData, filename: filename, typeHint: uti)
                                exporter.mediaDirectoryType = self.mediaDirectoryType
                                if let options = self.imageOptions {
                                    exporter.options = options
                                    if options.exportImageType == nil, let utiToUse = uti {
                                        exporter.options.exportImageType = self.preferedExportTypeFor(uti: utiToUse)
                                    }
                                }
                                let exportProgress = exporter.export(onCompletion: { (imageExport) in
                                    onCompletion(imageExport)
                                }, onError: onError)
                                progress.addChild(exportProgress, withPendingUnitCount: MediaExportProgressUnits.halfDone)
        })
        return progress
    }

    func preferedExportTypeFor(uti: String) -> String? {
        guard !self.allowableFileExtensions.isEmpty,
            let extensionType = UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue() as String?
            else {
            return nil
        }
        if allowableFileExtensions.contains(extensionType) {
            return uti
        } else {
            return kUTTypeJPEG as String
        }
    }

    /// Exports and writes an asset's video data to a local Media URL.
    ///
    /// - parameter onCompletion: Called on successful export, with the local file URL of the exported asset.
    /// - parameter onError: Called if an error was encountered during export.
    ///
    fileprivate func exportVideo(forAsset asset: PHAsset, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        guard asset.mediaType == .video else {
            onError(exporterErrorWith(error: AssetExportError.expectedPHAssetVideoType))
            return Progress.discreteCompletedProgress()
        }
        // Get the resource matching the type, to export.
        let resources = PHAssetResource.assetResources(for: asset).filter({ $0.type == .video })
        guard let videoResource = resources.first else {
            onError(exporterErrorWith(error: AssetExportError.unavailablePHAssetVideoResource))
            return Progress.discreteCompletedProgress()
        }

        // Configure a video exporter to handle an export session.
        let exporterVideoOptions = videoOptions ?? MediaVideoExporter.Options()
        let originalFilename = videoResource.originalFilename

        // Request an export session, which may take time to download the complete video data.
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        let progress = Progress.discreteProgress(totalUnitCount: MediaExportProgressUnits.done)
        progress.isCancellable = true
        options.progressHandler = { (progressValue, error, stop, info) in
            progress.completedUnitCount = Int64(progressValue * Double(MediaExportProgressUnits.halfDone))
            if progress.isCancelled {
                stop.pointee = true
            }
        }
        imageManager.requestExportSession(forVideo: asset,
                                          options: options,
                                          exportPreset: exporterVideoOptions.exportPreset,
                                          resultHandler: { (session, info) -> Void in
                                            progress.completedUnitCount = MediaExportProgressUnits.halfDone
                                            guard let session = session else {
                                                if let error = info?[PHImageErrorKey] as? Error {
                                                    onError(self.exporterErrorWith(error: error))
                                                } else {
                                                    onError(AssetExportError.failedRequestingVideoExportSession)
                                                }
                                                return
                                            }
                                            let videoExporter = MediaVideoExporter(session: session, filename: originalFilename)
                                            videoExporter.options = exporterVideoOptions
                                            videoExporter.mediaDirectoryType = self.mediaDirectoryType
                                            let exportProgress = videoExporter.export(onCompletion: { (videoExport) in
                                                onCompletion(videoExport)
                                            },
                                                                 onError: onError)
                                            progress.addChild(exportProgress, withPendingUnitCount: MediaExportProgressUnits.halfDone)
        })
        return progress
    }

    /// Exports and writes an asset's GIF data to a local Media URL.
    ///
    /// - parameter onCompletion: Called on successful export, with the local file URL of the exported asset.
    /// - parameter onError: Called if an error was encountered during export.
    ///
    fileprivate func exportGIF(forAsset asset: PHAsset, resource: PHAssetResource, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {

        guard UTTypeEqual(resource.uniformTypeIdentifier as CFString, kUTTypeGIF) else {
            onError(exporterErrorWith(error: AssetExportError.expectedPHAssetGIFType))
            return Progress.discreteCompletedProgress()
        }
        let url: URL
        do {
            url = try mediaFileManager.makeLocalMediaURL(withFilename: resource.originalFilename,
                                                         fileExtension: "gif")
        } catch {
            onError(exporterErrorWith(error: error))
            return Progress.discreteCompletedProgress()
        }
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        let progress = Progress.discreteProgress(totalUnitCount: MediaExportProgressUnits.done)
        progress.isCancellable = false
        let manager = PHAssetResourceManager.default()
        manager.writeData(for: resource,
                          toFile: url,
                          options: options,
                          completionHandler: { (error) in
                            progress.completedUnitCount = progress.totalUnitCount
                            if let error = error {
                                onError(self.exporterErrorWith(error: error))
                                return
                            }
                            onCompletion(MediaExport(url: url,
                                                    fileSize: url.fileSize,
                                                    width: url.pixelSize.width,
                                                    height: url.pixelSize.height,
                                                    duration: 0))
        })
        return progress
    }
}
