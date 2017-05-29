import Foundation
import Photos
import MobileCoreServices
import AVFoundation

typealias SuccessHandler = (_ resultingSize: CGSize) -> ()
typealias ErrorHandler = (_ error: NSError) -> ()

@objc protocol ExportableAsset: NSObjectProtocol {
    /// Exports an asset to a file URL with the desired targetSize and removing geolocation if requested.
    /// The targetSize is the maximum resolution permited, the resultSize will normally be a lower value that
    /// maitains the aspect ratio of the asset.
    ///
    /// - Note: Images aren't scaled up, so if you pass a `maximumResolution` that's larger than the original
    ///         image, it will not resize.
    ///
    /// - Parameters:
    ///     - url: file url to where the asset should be exported, this must be writable location
    ///     - targetUTI: the UTI format to use when exporting the asset
    ///     - maximumResolution:  the maximum pixel resolution that the asset can have after exporting.
    ///     - stripGeoLocation: if true any geographic location existent on the metadata of the asset will be stripped
    ///     - successHandler:  a handler that will be invoked on success with the resulting resolution of the asset exported
    ///     - errorHandler: a handler that will be invoked when some error occurs when generating the exported file for the asset
    ///
    func exportToURL(_ url: URL,
                     targetUTI: String,
                     maximumResolution: CGSize,
                     stripGeoLocation: Bool,
                     synchronous: Bool,
                     successHandler: @escaping SuccessHandler,
                     errorHandler: @escaping ErrorHandler)

    /// Exports an image thumbnail of the asset to a file URL that respects the targetSize.
    /// The targetSize is the maximum resulting resolution  the resultSize will normally be a lower value that
    /// mantains the aspect ratio of the asset
    ///
    /// - Parameters:
    ///     - url: File url to where the asset should be exported, this must be writable location.
    ///     - targetSize: The maximum pixel resolution that the file can have after exporting.
    ///                   If CGSizeZero is provided the original size of image is returned.
    ///     - successHandler: A handler that will be invoked on success with the resulting resolution of the image
    ///     - errorHandler: A handler that will be invoked when some error occurs when generating the thumbnail
    ///
    func exportThumbnailToURL(_ url: URL,
                              targetSize: CGSize,
                              synchronous: Bool,
                              successHandler: @escaping SuccessHandler,
                              errorHandler: @escaping ErrorHandler)

    /**
     Export the original asset without any modification to the specified URL

     - parameter toURL:          the location to export to
     - parameter successHandler: A handler that will be invoked on success with the resulting resolution of the image.
     - parameter errorHandler:   A handler that will be invoked when some error occurs.

     */
    func exportOriginalImage(_ toURL: URL, successHandler: @escaping SuccessHandler, errorHandler: @escaping ErrorHandler)

    func originalUTI() -> String?

    /// The MediaType for the asset
    ///
    var assetMediaType: MediaType { get }

    /// The default UTI for thumbnails
    ///
    var defaultThumbnailUTI: String { get }
}

extension PHAsset: ExportableAsset {

    internal func exportToURL(_ url: URL,
        targetUTI: String,
        maximumResolution: CGSize,
        stripGeoLocation: Bool,
        synchronous: Bool,
        successHandler: @escaping SuccessHandler,
        errorHandler: @escaping ErrorHandler) {

        switch self.mediaType {
        case .image:
            exportImageToURL(url,
                targetUTI: targetUTI,
                maximumResolution: maximumResolution,
                stripGeoLocation: stripGeoLocation,
                synchronous: synchronous,
                successHandler: successHandler,
                errorHandler: errorHandler)
        case .video:
            exportVideoToURL(url,
                targetUTI: targetUTI,
                maximumResolution: maximumResolution,
                stripGeoLocation: stripGeoLocation,
                successHandler: successHandler,
                errorHandler: errorHandler)
        default:
            errorHandler(errorForCode(.unsupportedAssetType,
                failureReason: NSLocalizedString("This media type is not supported on WordPress.",
                                                 comment: "Error reason to display when exporting an unknow asset type from the device library")))
        }
    }

    internal func exportImageToURL(_ url: URL,
        targetUTI: String,
        maximumResolution: CGSize,
        stripGeoLocation: Bool,
        synchronous: Bool,
        successHandler: @escaping SuccessHandler,
        errorHandler: @escaping ErrorHandler) {

        let pixelSize = CGSize(width: pixelWidth, height: pixelHeight)
        let requestedSize = maximumResolution.clamp(min: CGSize.zero, max: pixelSize)

        exportImageWithSize(requestedSize, synchronous: synchronous) { (image, info) in
            guard let image = image else {
                if let error = info?[PHImageErrorKey] as? NSError {
                    errorHandler(error)
                } else {
                    errorHandler(self.errorForCode(.failedToExport,
                        failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
                        ))
                }
                return
            }
            self.requestMetadataWithCompletionBlock({ (metadata) -> () in
                do {
                    var attributesToRemove = [String]()
                    if (stripGeoLocation) {
                        attributesToRemove.append(kCGImagePropertyGPSDictionary as String)
                    }
                    var exportMetadata = self.removeAttributes(attributesToRemove, fromMetadata: metadata)
                    exportMetadata = self.matchMetadata(exportMetadata, image: image)
                    try image.writeToURL(url, type: targetUTI, compressionQuality: 0.9, metadata: exportMetadata)
                    successHandler(image.size)
                } catch let error as NSError {
                    errorHandler(error)
                }
            }, failureBlock: { (error) -> () in
                errorHandler(error)
            })
        }
    }

    func exportMaximumSizeImage(_ completion: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) {
        let targetSize = CGSize(width: pixelWidth, height: pixelHeight)
        exportImageWithSize(targetSize, synchronous: false, completion: completion)
    }

    func exportImageWithSize(_ targetSize: CGSize, synchronous: Bool, completion: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) {
        let options = PHImageRequestOptions()
        options.version = .current
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isSynchronous = synchronous
        options.isNetworkAccessAllowed = true

        let manager = PHImageManager.default()
        manager.requestImage(for: self,
                                     targetSize: targetSize,
                                     contentMode: .aspectFit,
                                     options: options) { (image, info) in
            completion(image, info)
        }
    }

    func exportOriginalImage(_ toURL: URL, successHandler: @escaping SuccessHandler, errorHandler: @escaping ErrorHandler) {
        let pixelSize = CGSize(width: pixelWidth, height: pixelHeight)
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        let manager = PHAssetResourceManager.default()
        let resources = PHAssetResource.assetResources(for: self)
        let filteredResources = resources.filter { (resource) -> Bool in
            return resource.type == .photo
        }
        if let resource = filteredResources.first {
            manager.writeData(for: resource, toFile: toURL, options: options) { (error) in
                if let error = error {
                    errorHandler(error as NSError)
                    return
                }
                successHandler(pixelSize)
            }
        } else {
            errorHandler(self.errorForCode(.failedToExport,
                failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
                ))
        }
    }

    func removeAttributes(_ attributes: [String], fromMetadata: [String: AnyObject]) -> [String: AnyObject] {
        var resultingMetadata = fromMetadata
        for attribute in attributes {
            resultingMetadata.removeValue(forKey: attribute)
            if attribute == kCGImagePropertyOrientation as String {
                if let tiffMetadata = resultingMetadata[kCGImagePropertyTIFFDictionary as String] as? [String: AnyObject] {
                    var newTiffMetadata = tiffMetadata
                    newTiffMetadata.removeValue(forKey: kCGImagePropertyTIFFOrientation as String)
                    resultingMetadata[kCGImagePropertyTIFFDictionary as String] = newTiffMetadata as AnyObject?
                }
            }
        }
        return resultingMetadata
    }

    /// Makes sure the metadata of the image is matching the attributes in the Image.
    ///
    /// - Parameters:
    ///     - metadata: The original metadata of the image.
    ///     - image: The current image.
    ///
    /// - Returns: A new metadata object where the values match the values on the UIImage
    ///
    func matchMetadata(_ metadata: [String: AnyObject], image: UIImage) -> [String: AnyObject] {
        var resultingMetadata = metadata
        let correctOrientation = image.metadataOrientation
        resultingMetadata[kCGImagePropertyOrientation as String] = Int(correctOrientation.rawValue) as AnyObject?
        if var tiffMetadata = resultingMetadata[kCGImagePropertyTIFFDictionary as String] as? [String: AnyObject] {
            tiffMetadata[kCGImagePropertyTIFFOrientation as String] = Int(correctOrientation.rawValue) as AnyObject?
            resultingMetadata[kCGImagePropertyTIFFDictionary as String] = tiffMetadata as AnyObject?
        }

        return resultingMetadata
    }

    func exportVideoToURL(_ url: URL,
        targetUTI: String,
        maximumResolution: CGSize,
        stripGeoLocation: Bool,
        successHandler: @escaping SuccessHandler,
        errorHandler: @escaping ErrorHandler) {

            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestExportSession(forVideo: self,
                options: options,
                exportPreset: AVAssetExportPresetPassthrough) { (exportSession, info) -> Void in
                    guard let exportSession = exportSession
                    else {
                        if let error = info?[PHImageErrorKey] as? NSError {
                            errorHandler(error)
                        } else {
                            errorHandler(self.errorForCode(.failedToExport,
                                failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
                                ))
                        }
                        return
                    }
                    exportSession.outputFileType = targetUTI
                    exportSession.shouldOptimizeForNetworkUse = true
                    if stripGeoLocation {
                        exportSession.metadataItemFilter = AVMetadataItemFilter.forSharing()
                    }
                    exportSession.outputURL = url
                    exportSession.exportAsynchronously(completionHandler: { () -> Void in
                        guard exportSession.status == .completed else {
                            if let error = exportSession.error {
                                errorHandler(error as NSError)
                            }
                            return
                        }
                        successHandler(CGSize(width: self.pixelWidth, height: self.pixelHeight))
                    })
            }
    }

    func exportThumbnailToURL(_ url: URL,
        targetSize: CGSize,
        synchronous: Bool,
        successHandler: @escaping SuccessHandler,
        errorHandler: @escaping ErrorHandler) {
            let options = PHImageRequestOptions()
            options.version = .current
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isSynchronous = synchronous
            options.isNetworkAccessAllowed = true
            var requestedSize = targetSize
            if (requestedSize == CGSize.zero) {
                requestedSize = PHImageManagerMaximumSize
            }

            PHImageManager.default().requestImage(for: self, targetSize: requestedSize, contentMode: .aspectFit, options: options) { (image, info) -> Void in
                guard let image = image
                else {
                    if let error = info?[PHImageErrorKey] as? NSError {
                        errorHandler(error)
                    } else {
                        errorHandler(self.errorForCode(.failedToExport,
                            failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
                            ))
                    }
                    return
                }
                do {
                    try image.writeToURL(url, type: self.defaultThumbnailUTI, compressionQuality: 0.9, metadata: nil)
                    successHandler(image.size)
                } catch let error as NSError {
                    errorHandler(error)
                }
            }
    }

    var defaultThumbnailUTI: String {
        get {
            return kUTTypeJPEG as String
        }
    }

    var assetMediaType: MediaType {
        get {
            if self.mediaType == .image {
                return .image
            } else if (self.mediaType == .video) {
                /** HACK: Sergio Estevao (2015-11-09): We ignore allowsFileTypes for videos in WP.com
                 because we have an exception on the server for mobile that allows video uploads event
                 if videopress is not enabled.
                 */
                return .video
            }
            return .document
        }
    }

    // MARK: - Error Handling

    enum ErrorCode: Int {
        case unsupportedAssetType = 1
        case failedToExport = 2
        case failedToExportMetadata = 3
    }

    fileprivate func errorForCode(_ errorCode: ErrorCode, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        let error = NSError(domain: "PHAsset+ExporterExtensions", code: errorCode.rawValue, userInfo: userInfo)

        return error
    }

    func requestMetadataWithCompletionBlock(_ completionBlock: @escaping (_ metadata: [String: AnyObject]) ->(), failureBlock: @escaping (_ error: NSError) -> ()) {
        let editOptions = PHContentEditingInputRequestOptions()
        editOptions.isNetworkAccessAllowed = true
        self.requestContentEditingInput(with: editOptions) { (contentEditingInput, info) -> Void in
            guard let contentEditingInput = contentEditingInput,
                let fullSizeImageURL = contentEditingInput.fullSizeImageURL,
                let image = CIImage(contentsOf: fullSizeImageURL) else {
                    completionBlock([String: AnyObject]())
                    if let error = info[PHImageErrorKey] as? NSError {
                        failureBlock(error)
                    } else {
                        failureBlock(self.errorForCode(.failedToExportMetadata,
                            failureReason: NSLocalizedString("Unable to export metadata", comment: "Error reason to display when the export of a image from device library fails")
                            ))
                    }
                    return
            }
            completionBlock(image.properties as [String : AnyObject])
        }
    }

    func originalUTI() -> String? {
        let resources = PHAssetResource.assetResources(for: self)
        var types: [PHAssetResourceType.RawValue] = []
        if (mediaType == PHAssetMediaType.image) {
            types = [PHAssetResourceType.photo.rawValue]
        } else if (mediaType == PHAssetMediaType.video) {
            types = [PHAssetResourceType.video.rawValue]
        }
        for resource in resources {
            if (types.contains(resource.type.rawValue) ) {
                return resource.uniformTypeIdentifier
            }
        }
        return nil
    }

    func originalFilename() -> String? {
        let resources = PHAssetResource.assetResources(for: self)
        var types: [PHAssetResourceType.RawValue] = []
        if (mediaType == PHAssetMediaType.image) {
            types = [PHAssetResourceType.photo.rawValue]
        } else if (mediaType == PHAssetMediaType.video) {
            types = [PHAssetResourceType.video.rawValue]
        }
        for resource in resources {
            if (types.contains(resource.type.rawValue) ) {
                return resource.originalFilename
            }
        }
        return nil
    }
}

extension String {

    static func StringFromCFType(_ cfValue: Unmanaged<CFString>?) -> String? {
        let value = Unmanaged.fromOpaque(cfValue!.toOpaque()).takeUnretainedValue() as CFString
        if CFGetTypeID(value) == CFStringGetTypeID() {
            return value as String
        } else {
            return nil
        }
    }

}
