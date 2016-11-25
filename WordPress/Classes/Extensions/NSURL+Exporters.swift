import Foundation
import Photos
import MobileCoreServices
import AVFoundation

extension NSURL: ExportableAsset {

    func exportToURL(url: NSURL,
        targetUTI: String,
        maximumResolution: CGSize,
        stripGeoLocation: Bool,
        synchronous: Bool,
        successHandler: SuccessHandler,
        errorHandler: ErrorHandler) {

        switch assetMediaType {
        case .Image:
            exportImageToURL(url,
                targetUTI: targetUTI,
                maximumResolution: maximumResolution,
                stripGeoLocation: stripGeoLocation,
                synchronous: synchronous,
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
        synchronous: Bool,
        successHandler: SuccessHandler,
        errorHandler: ErrorHandler)
    {

        let requestedSize = maximumResolution.clamp(min: CGSizeZero, max: pixelSize)
        let metadataOptions: [NSString:NSObject] = [kCGImageSourceShouldCache: false]
        let scaleOptions: [NSString: NSObject] = [
            kCGImageSourceThumbnailMaxPixelSize: max(requestedSize.width, requestedSize.height),
            kCGImageSourceCreateThumbnailFromImageAlways: true
        ]
        guard let imageSource = CGImageSourceCreateWithURL(self, nil),
              let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, metadataOptions),
              let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, scaleOptions)
        else {
            errorHandler(error: errorForCode(.FailedToExport,
                failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
                ))
            return
        }
        let image = UIImage(CGImage: scaledImage)
        var exportMetadata : [String:AnyObject]? = nil
        if let metadata = imageProperties as NSDictionary as? [String:AnyObject] {
            exportMetadata = metadata
            if stripGeoLocation {
                let attributesToRemove = [kCGImagePropertyGPSDictionary as String]
                exportMetadata = removeAttributes(attributesToRemove, fromMetadata: metadata)
            }
        }

        do {
            try image.writeToURL(url, type: targetUTI, compressionQuality: 0.9, metadata: exportMetadata)
            successHandler(resultingSize: image.size)
        } catch let error as NSError {
            errorHandler(error: error)
        } catch {
            errorHandler(error: errorForCode(.FailedToExport,
                                                  failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
            ))
        }
    }

    func exportOriginalImage(toURL: NSURL, successHandler: SuccessHandler, errorHandler: ErrorHandler) {
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.copyItemAtURL(self, toURL: toURL)
        } catch let error as NSError {
            errorHandler(error: error)
        } catch {
            errorHandler(error: errorForCode(.FailedToExport,
                                                  failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
            ))
        }
        successHandler(resultingSize: pixelSize)
    }

    func exportVideoToURL(url: NSURL,
        targetUTI: String,
        maximumResolution: CGSize,
        stripGeoLocation: Bool,
        successHandler: SuccessHandler,
        errorHandler: ErrorHandler) {

        let asset = AVURLAsset(URL: self)
        guard let track = asset.tracksWithMediaType(AVMediaTypeVideo).first else {
            errorHandler(error: errorForCode(.FailedToExport,
                failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
                ))
            return
        }
        let size = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform)
        let pixelWidth = fabs(size.width)
        let pixelHeight = fabs(size.height)

        guard
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
        else {

            errorHandler(error: errorForCode(.FailedToExport,
                failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
                ))
            return
        }
        exportSession.outputFileType = targetUTI
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.outputURL = url
        exportSession.exportAsynchronouslyWithCompletionHandler({ () -> Void in
            guard exportSession.status == .Completed else {
                if let error = exportSession.error {
                    errorHandler(error: error)
                }
                return
            }
            successHandler(resultingSize: CGSize(width: pixelWidth, height: pixelHeight))
        })
    }

    func exportThumbnailToURL(url: NSURL,
        targetSize: CGSize,
        synchronous: Bool,
        successHandler: SuccessHandler,
        errorHandler: ErrorHandler) {
        if isImage {
            exportToURL(url,
                        targetUTI: defaultThumbnailUTI,
                        maximumResolution: targetSize,
                        stripGeoLocation: true,
                        synchronous: synchronous,
                        successHandler: successHandler,
                        errorHandler: errorHandler)
        } else if isVideo {
            do {
                let asset = AVURLAsset(URL: self, options: nil)
                let imgGenerator = AVAssetImageGenerator(asset: asset)
                imgGenerator.maximumSize = targetSize
                imgGenerator.appliesPreferredTrackTransform = true
                let cgImage = try imgGenerator.copyCGImageAtTime(CMTimeMake(0, 1), actualTime: nil)
                let uiImage = UIImage(CGImage: cgImage)
                try uiImage.writeJPEGToURL(url)
                successHandler(resultingSize: uiImage.size)
            } catch let error as NSError {
                errorHandler(error: error)
            } catch {
                errorHandler(error: errorForCode(.FailedToExport,
                    failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
                    ))
            }
        } else {
            errorHandler(error: errorForCode(.FailedToExport,
                failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
                ))
        }
    }

    func originalUTI() -> String? {
        return typeIdentifier
    }

    var defaultThumbnailUTI: String {
        get {
            return kUTTypeJPEG as String
        }
    }

    var assetMediaType: MediaType {
        get {
            if isImage {
                return .Image
            } else if (isVideo) {
                return .Video
            }
            return .Document
        }
    }

    //MARK: - Helper methods

    var pixelSize: CGSize {
        get {
            if isVideo {
                let asset = AVAsset(URL: self)
                guard let track = asset.tracksWithMediaType(AVMediaTypeVideo).first else {
                    return CGSizeZero
                }
                let size = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform)
                return size
            } else if isImage {
                let options: [NSString:NSObject] = [kCGImageSourceShouldCache: false]
                guard
                    let imageSource = CGImageSourceCreateWithURL(self, nil),
                    let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, options)
                    else {
                        return CGSizeZero
                }

                let imageDictionary = imageProperties as NSDictionary
                guard
                    let pixelWidth = imageDictionary[kCGImagePropertyPixelWidth as NSString] as? Int,
                    let pixelHeight = imageDictionary[kCGImagePropertyPixelHeight as NSString] as? Int
                    else {
                        return CGSizeZero
                }

                return CGSize(width: pixelWidth, height: pixelHeight)
            } else {
                return CGSizeZero
            }
        }
    }

    var typeIdentifier: String? {
        guard fileURL else { return nil }
        do {
            let data = try bookmarkDataWithOptions(NSURLBookmarkCreationOptions.MinimalBookmark, includingResourceValuesForKeys:[NSURLTypeIdentifierKey], relativeToURL: nil)
            guard
                let resourceValues = NSURL.resourceValuesForKeys([NSURLTypeIdentifierKey], fromBookmarkData:data),
                let typeIdentifier = resourceValues[NSURLTypeIdentifierKey] as? String else {
                    return nil
            }
            return typeIdentifier
        } catch {
            return nil
        }
    }

    var mimeType: String {
        guard let uti = typeIdentifier,
            let mimeType = UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassMIMEType)?.takeUnretainedValue() as? String
            else {
                return "application/octet-stream"
        }

        return mimeType
    }

    var isVideo: Bool {
        guard let uti = typeIdentifier else {
            return false
        }

        return UTTypeConformsTo(uti as CFString, kUTTypeMovie)
    }

    var isImage: Bool {
        guard let uti = typeIdentifier else {
            return false
        }

        return UTTypeConformsTo(uti as CFString, kUTTypeImage)
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

    /// Makes sure the metadata of the image is matching the attributes in the Image.
    ///
    /// - Parameters:
    ///     - metadata: The original metadata of the image.
    ///     - image: The current image.
    ///
    /// - Returns: A new metadata object where the values match the values on the UIImage
    ///
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

    // MARK: - Error Handling

    enum ErrorCode : Int {
        case UnsupportedAssetType = 1
        case FailedToExport = 2
        case FailedToExportMetadata = 3
    }

    private func errorForCode(errorCode: ErrorCode, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        let error = NSError(domain: "NSURL+ExporterExtensions", code: errorCode.rawValue, userInfo: userInfo)

        return error
    }

}
