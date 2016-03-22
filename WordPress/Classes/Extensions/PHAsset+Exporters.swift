import Foundation
import Photos
import MobileCoreServices
import AVFoundation

extension PHAsset {
    
    typealias SuccessHandler = (resultingSize: CGSize) -> ()
    typealias ErrorHandler = (error: NSError) -> ()

    /**
     Exports an asset to a file URL with the desired targetSize and removing geolocation if requested. 
     The targetSize is the maximum resolution permited, the resultSize will normally be a lower value that maitains the aspect ratio of the asset.
     
     - Note: Images aren't scaled up, so if you pass a `maximumResolution` that's larger than the original image, it will not resize.

     - Parameters:
        - url: file url to where the asset should be exported, this must be writable location
        - targetUTI: the UTI format to use when exporting the asset
        - maximumResolution:  the maximum pixel resolution that the asset can have after exporting.
        - stripGeoLocation: if true any geographic location existent on the metadata of the asset will be stripped
        - successHandler:  a handler that will be invoked on success with the resulting resolution of the asset exported
        - errorHandler: a handler that will be invoked when some error occurs when generating the exported file for the asset
     */
    func exportToURL(url: NSURL,
        targetUTI: String,
        maximumResolution: CGSize,
        stripGeoLocation: Bool,
        successHandler: SuccessHandler,
        errorHandler: ErrorHandler) {
        
        switch self.mediaType {
        case .Image:
            exportImageToURL(url,
                targetUTI: targetUTI,
                maximumResolution: maximumResolution,
                stripGeoLocation: stripGeoLocation,
                successHandler: successHandler,
                errorHandler: errorHandler)
        case .Video:
            exportVideoToURL(url,
                targetUTI: targetUTI,
                maximumResolution: maximumResolution,
                stripGeoLocation: stripGeoLocation,
                successHandler: successHandler,
                errorHandler: errorHandler)
        default:
            errorHandler(error: errorForCode(.UnsupportedAssetType,
                failureReason: NSLocalizedString("This media type is not supported on WordPress.",
                                                 comment: "Error reason to display when exporting an unknow asset type from the device library")))
        }
    }
    
    func exportImageToURL(url: NSURL,
        targetUTI: String,
        maximumResolution: CGSize,
        stripGeoLocation: Bool,
        successHandler: SuccessHandler,
        errorHandler: ErrorHandler) {
        
        let options = PHImageRequestOptions()
        options.version = .Current
        options.deliveryMode = .HighQualityFormat
        options.resizeMode = .Exact
        options.synchronous = false
        options.networkAccessAllowed = true

        let pixelSize = CGSize(width: pixelWidth, height: pixelHeight)
        let requestedSize = maximumResolution.clamp(min: CGSizeZero, max: pixelSize)

            PHImageManager.defaultManager().requestImageForAsset(self, targetSize: requestedSize, contentMode: .AspectFit, options: options) { (image, info) -> Void in
            guard let image = image else {
                if let error = info?[PHImageErrorKey] as? NSError {
                    errorHandler(error: error)
                } else {
                    errorHandler(error: self.errorForCode(.FailedToExport,
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
                    successHandler(resultingSize: image.size)
                } catch let error as NSError {
                    errorHandler(error: error)
                }
            }, failureBlock:{(error) -> () in
                errorHandler(error: error)
            })
        }
    }
    
    func removeAttributes(attributes: [String], fromMetadata: [String:AnyObject]) -> [String:AnyObject]{
        var resultingMetadata = fromMetadata
        for attribute in attributes {
            resultingMetadata.removeValueForKey(attribute)
            if attribute == kCGImagePropertyOrientation as String{
                if let tiffMetadata = resultingMetadata[kCGImagePropertyTIFFDictionary as String] as? [String:AnyObject]{
                    var newTiffMetadata = tiffMetadata
                    newTiffMetadata.removeValueForKey(kCGImagePropertyTIFFOrientation as String)
                    resultingMetadata[kCGImagePropertyTIFFDictionary as String] = newTiffMetadata
                }
            }
        }
        return resultingMetadata
    }

    /**
     Makes sure the metadata of the image is matching the attributes in the Image.

     - parameter metadata: the original metadata of the image
     - parameter image:    the current image

     - returns: a new metadata object where the values match the values on the UIImage
     */
    func matchMetadata(metadata: [String:AnyObject], image: UIImage) -> [String:AnyObject] {
        var resultingMetadata = metadata
        let correctOrientation = image.metadataOrientation
        resultingMetadata[kCGImagePropertyOrientation as String] = Int(correctOrientation.rawValue)
        if var tiffMetadata = resultingMetadata[kCGImagePropertyTIFFDictionary as String] as? [String:AnyObject]{
            tiffMetadata[kCGImagePropertyTIFFOrientation as String] = Int(correctOrientation.rawValue)
            resultingMetadata[kCGImagePropertyTIFFDictionary as String] = tiffMetadata
        }

        return resultingMetadata
    }

    func exportVideoToURL(url: NSURL,
        targetUTI: String,
        maximumResolution: CGSize,
        stripGeoLocation: Bool,
        successHandler: SuccessHandler,
        errorHandler: ErrorHandler) {
            
            let options = PHVideoRequestOptions()
            options.networkAccessAllowed = true
            PHImageManager.defaultManager().requestExportSessionForVideo(self,
                options: options,
                exportPreset: AVAssetExportPresetPassthrough) { (exportSession, info) -> Void in
                    guard let exportSession = exportSession
                    else {
                        if let error = info?[PHImageErrorKey] as? NSError {
                            errorHandler(error: error)
                        } else {
                            errorHandler(error: self.errorForCode(.FailedToExport,
                                failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
                                ))
                        }
                        return
                    }
                    exportSession.outputFileType = targetUTI;
                    exportSession.shouldOptimizeForNetworkUse = true
                    exportSession.outputURL = url
                    exportSession.exportAsynchronouslyWithCompletionHandler({ () -> Void in
                        guard exportSession.status == .Completed else {
                            if let error = exportSession.error {
                                errorHandler(error: error)
                            }
                            return;
                        }
                        successHandler(resultingSize: CGSize(width: self.pixelWidth, height: self.pixelHeight))
                    })
            }
    }
    
    /**
     Exports an image thumbnail of the asset to a file URL that respects the targetSize.
     The targetSize is the maximum resulting resolution  the resultSize will normally be a lower value that mantains the aspect ratio of the asset
     
     - Parameters:
        - url: file url to where the asset should be exported, this must be writable location
        - targetSize:  the maximum pixel resolution that the file can have after exporting. If CGSizeZero is provided the original size of image is returned.
        - successHandler: a handler that will be invoked on success with the resulting resolution of the image
        - errorHandler: a handler that will be invoked when some error occurs when generating the thumbnail
     */
    func exportThumbnailToURL(url: NSURL,
        targetSize: CGSize,
        synchronous: Bool,
        successHandler: SuccessHandler,
        errorHandler: ErrorHandler) {
            let options = PHImageRequestOptions()
            options.version = .Current
            options.deliveryMode = .HighQualityFormat
            options.resizeMode = .Fast
            options.synchronous = synchronous
            options.networkAccessAllowed = true
            var requestedSize = targetSize
            if (requestedSize == CGSize.zero) {
                requestedSize = PHImageManagerMaximumSize
            }
            
            PHImageManager.defaultManager().requestImageForAsset(self, targetSize: requestedSize, contentMode: .AspectFit, options: options) { (image, info) -> Void in
                guard let image = image
                else {
                    if let error = info?[PHImageErrorKey] as? NSError {
                        errorHandler(error: error)
                    } else {
                        errorHandler(error: self.errorForCode(.FailedToExport,
                            failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
                            ))
                    }
                    return
                }
                do {
                    try image.writeToURL(url, type: self.defaultThumbnailUTI, compressionQuality: 0.9, metadata: nil)
                    successHandler(resultingSize: image.size)
                } catch let error as NSError {
                    errorHandler(error: error)
                }
            }
    }
    
    var defaultThumbnailUTI: String {
        get {
            return kUTTypeJPEG as String
        }
    }
    
    // MARK: - Error Handling
    
    enum ErrorCode : Int {
        case UnsupportedAssetType = 1
        case FailedToExport = 2
        case FailedToExportMetadata = 3
    }
    
    private func errorForCode(errorCode: ErrorCode, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        let error = NSError(domain: "PHAsset+ExporterExtensions", code: errorCode.rawValue, userInfo: userInfo)
        
        return error
    }
    
    func requestMetadataWithCompletionBlock(completionBlock: (metadata:[String:AnyObject]) ->(), failureBlock: (error:NSError) -> ()) {
        let editOptions = PHContentEditingInputRequestOptions();
        editOptions.networkAccessAllowed = true;
        self.requestContentEditingInputWithOptions(editOptions) { (contentEditingInput, info) -> Void in
            guard let contentEditingInput = contentEditingInput,
                let fullSizeImageURL = contentEditingInput.fullSizeImageURL,
                let image = CIImage(contentsOfURL: fullSizeImageURL) else {
                    completionBlock(metadata:[String:AnyObject]())
                    if let error = info[PHImageErrorKey] as? NSError {
                        failureBlock(error: error)
                    } else {
                        failureBlock(error: self.errorForCode(.FailedToExportMetadata,
                            failureReason: NSLocalizedString("Unable to export metadata", comment: "Error reason to display when the export of a image from device library fails")
                            ))
                    }
                    return
            }
            completionBlock(metadata:image.properties)
        }
    }
    
    func originalUTI() -> String? {
        let resources = PHAssetResource.assetResourcesForAsset(self)
        var types = [];
        if (mediaType == PHAssetMediaType.Image) {
            types = [PHAssetResourceType.Photo.rawValue]
        } else if (mediaType == PHAssetMediaType.Video){
            types = [PHAssetResourceType.Video.rawValue]
        }
        for resource in resources {
            if (types.containsObject(resource.type.rawValue) ) {
                return resource.uniformTypeIdentifier
            }
        }
        return nil
    }
    
    func originalFilename() -> String? {
        let resources = PHAssetResource.assetResourcesForAsset(self)
        var types = [];
        if (mediaType == PHAssetMediaType.Image) {
            types = [PHAssetResourceType.Photo.rawValue]
        } else if (mediaType == PHAssetMediaType.Video){
            types = [PHAssetResourceType.Video.rawValue]
        }
        for resource in resources {
            if (types.containsObject(resource.type.rawValue) ) {
                return resource.originalFilename
            }
        }
        return nil
    }
}

extension String {

    static func StringFromCFType(cfValue: Unmanaged<CFString>?) -> String? {
        let value = Unmanaged.fromOpaque(cfValue!.toOpaque()).takeUnretainedValue() as CFString
        if CFGetTypeID(value) == CFStringGetTypeID(){
            return value as String
        } else {
            return nil
        }
    }

}