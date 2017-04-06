import Foundation
import Photos
import MobileCoreServices
import AVFoundation

extension NSURL: ExportableAsset {

    func exportToURL(_ url: URL,
                     targetUTI: String,
                     maximumResolution: CGSize,
                     stripGeoLocation: Bool,
                     synchronous: Bool,
                     successHandler: @escaping SuccessHandler,
                     errorHandler: @escaping ErrorHandler) {

        switch assetMediaType {
        case .image:
            exportImageToURL(url as NSURL,
                targetUTI: targetUTI,
                maximumResolution: maximumResolution,
                stripGeoLocation: stripGeoLocation,
                synchronous: synchronous,
                successHandler: successHandler,
                errorHandler: errorHandler)
        case .video:
            exportVideoToURL(url as NSURL,
                targetUTI: targetUTI,
                maximumResolution: maximumResolution,
                stripGeoLocation: stripGeoLocation,
                successHandler: successHandler,
                errorHandler: errorHandler)
        default:
            errorHandler(errorForCode(errorCode: .UnsupportedAssetType,
                failureReason: NSLocalizedString("This media type is not supported on WordPress.",
                                                 comment: "Error reason to display when exporting an unknown asset type.")))
        }
    }

    func exportImageToURL(_ url: NSURL,
        targetUTI: String,
        maximumResolution: CGSize,
        stripGeoLocation: Bool,
        synchronous: Bool,
        successHandler: SuccessHandler,
        errorHandler: ErrorHandler) {
        let requestedSize = maximumResolution.clamp(min: CGSize.zero, max: pixelSize)
        let metadataOptions: [NSString: NSObject] = [kCGImageSourceShouldCache: false as NSObject]
        let scaleOptions: [NSString: NSObject] = [
            kCGImageSourceThumbnailMaxPixelSize: (requestedSize.width > requestedSize.height ? requestedSize.width : requestedSize.height) as CFNumber,
            kCGImageSourceCreateThumbnailFromImageAlways: true as CFBoolean
        ]
        guard let imageSource = CGImageSourceCreateWithURL(self, nil),
              let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, metadataOptions as CFDictionary?),
              let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, scaleOptions as CFDictionary?)
        else {
            errorHandler(errorForCode(errorCode: .FailedToExport,
                failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image fails.")
                ))
            return
        }
        let image = UIImage(cgImage: scaledImage)
        var exportMetadata: [String: AnyObject]? = nil
        if let metadata = imageProperties as NSDictionary as? [String: AnyObject] {
            exportMetadata = metadata
            if stripGeoLocation {
                let attributesToRemove = [kCGImagePropertyGPSDictionary as String]
                exportMetadata = removeAttributes(attributes: attributesToRemove, fromMetadata: metadata)
            }
        }

        do {
            try image.writeToURL(url as URL, type: targetUTI, compressionQuality: 0.9, metadata: exportMetadata)
            successHandler(image.size)
        } catch let error as NSError {
            errorHandler(error)
        } catch {
            errorHandler(errorForCode(errorCode: .FailedToExport,
                                                  failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
            ))
        }
    }

    func exportOriginalImage(_ toURL: URL, successHandler: @escaping SuccessHandler, errorHandler: @escaping ErrorHandler) {
        let fileManager = FileManager.default
        do {
            try fileManager.copyItem(at: self as URL, to: toURL)
        } catch let error as NSError {
            errorHandler(error)
        } catch {
            errorHandler(errorForCode(errorCode: .FailedToExport,
                                                  failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
            ))
        }
        successHandler(pixelSize)
    }

    func exportVideoToURL(_ url: NSURL,
        targetUTI: String,
        maximumResolution: CGSize,
        stripGeoLocation: Bool,
        successHandler: @escaping SuccessHandler,
        errorHandler: @escaping ErrorHandler) {

        let asset = AVURLAsset(url: self as URL)
        guard let track = asset.tracks(withMediaType: AVMediaTypeVideo).first else {
            errorHandler(errorForCode(errorCode: .FailedToExport,
                failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of an media asset fails")
                ))
            return
        }
        let size = track.naturalSize.applying(track.preferredTransform)
        let pixelWidth = fabs(size.width)
        let pixelHeight = fabs(size.height)

        guard
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
        else {

            errorHandler(errorForCode(errorCode: .FailedToExport,
                failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of an media asset fails")
                ))
            return
        }
        exportSession.outputFileType = targetUTI
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.outputURL = url as URL
        exportSession.exportAsynchronously(completionHandler: { () -> Void in
            guard exportSession.status == .completed else {
                if let error = exportSession.error {
                    errorHandler(error as NSError)
                }
                return
            }
            successHandler(CGSize(width: pixelWidth, height: pixelHeight))
        })
    }

    func exportThumbnailToURL(_ url: URL,
        targetSize: CGSize,
        synchronous: Bool,
        successHandler: @escaping SuccessHandler,
        errorHandler: @escaping ErrorHandler) {
        if isImage {
            exportToURL(url,
                        targetUTI: defaultThumbnailUTI,
                        maximumResolution: targetSize,
                        stripGeoLocation: true,
                        synchronous: synchronous,
                        successHandler: successHandler,
                        errorHandler: errorHandler)
        } else if isVideo {
            let asset = AVURLAsset(url: self as URL, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.maximumSize = targetSize
            imgGenerator.appliesPreferredTrackTransform = true
            imgGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: CMTimeMake(0, 1))], completionHandler: { (time, cgImage, actualTime, result, error) in
                guard let cgImage = cgImage else {
                    if let error = error {
                        errorHandler(error as NSError)
                    } else {
                        errorHandler(self.errorForCode(errorCode: .FailedToExport,
                            failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
                            ))
                    }
                    return
                }
                let uiImage = UIImage(cgImage: cgImage)
                do {
                    try uiImage.writeJPEGToURL(url)
                        successHandler(uiImage.size)
                } catch let error as NSError {
                    errorHandler(error)
                } catch {
                    errorHandler(self.errorForCode(errorCode: .FailedToExport,
                        failureReason: NSLocalizedString("Unknown asset export error", comment: "Error reason to display when the export of a image from device library fails")
                        ))
                }
            })
        } else {
            errorHandler(errorForCode(errorCode: .FailedToExport,
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
                return .image
            } else if (isVideo) {
                return .video
            }
            return .document
        }
    }

    //MARK: - Helper methods

    var pixelSize: CGSize {
        get {
            if isVideo {
                let asset = AVAsset(url: self as URL)
                if let track = asset.tracks(withMediaType: AVMediaTypeVideo).first {
                    return track.naturalSize.applying(track.preferredTransform)
                }
            } else if isImage {
                let options: [NSString: NSObject] = [kCGImageSourceShouldCache: false as CFBoolean]
                if
                    let imageSource = CGImageSourceCreateWithURL(self, nil),
                    let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, options as CFDictionary?) as NSDictionary?,
                    let pixelWidth = imageProperties[kCGImagePropertyPixelWidth as NSString] as? Int,
                    let pixelHeight = imageProperties[kCGImagePropertyPixelHeight as NSString] as? Int
                {
                        return CGSize(width: pixelWidth, height: pixelHeight)
                }
            }
            return CGSize.zero
        }
    }

    var typeIdentifier: String? {
        guard isFileURL else { return nil }
        do {
            let data = try bookmarkData(options: NSURL.BookmarkCreationOptions.minimalBookmark, includingResourceValuesForKeys: [URLResourceKey.typeIdentifierKey], relativeTo: nil)
            guard
                let resourceValues = NSURL.resourceValues(forKeys: [URLResourceKey.typeIdentifierKey], fromBookmarkData: data),
                let typeIdentifier = resourceValues[URLResourceKey.typeIdentifierKey] as? String else {
                    return nil
            }
            return typeIdentifier
        } catch {
            return nil
        }
    }

    var mimeType: String {
        guard let uti = typeIdentifier,
            let mimeType = UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassMIMEType)?.takeUnretainedValue() as String?
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


    func removeAttributes(attributes: [String], fromMetadata: [String: AnyObject]) -> [String: AnyObject] {
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
    func matchMetadata(metadata: [String: AnyObject], image: UIImage) -> [String: AnyObject] {
        var resultingMetadata = metadata
        let correctOrientation = image.metadataOrientation
        resultingMetadata[kCGImagePropertyOrientation as String] = Int(correctOrientation.rawValue) as AnyObject?
        if var tiffMetadata = resultingMetadata[kCGImagePropertyTIFFDictionary as String] as? [String: AnyObject] {
            tiffMetadata[kCGImagePropertyTIFFOrientation as String] = Int(correctOrientation.rawValue) as AnyObject?
            resultingMetadata[kCGImagePropertyTIFFDictionary as String] = tiffMetadata as AnyObject?
        }

        return resultingMetadata
    }

    // MARK: - Error Handling

    enum ErrorCode: Int {
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
