import Foundation
import ImageIO

extension UIImage {
    // MARK: - Error Handling
    enum ErrorCode : Int {
        case FailedToWrite = 1
    }

    private func errorForCode(errorCode: ErrorCode, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        let error = NSError(domain: "UIImage+ImageIOExtensions", code: errorCode.rawValue, userInfo: userInfo)

        return error
    }

    /**
     Writes an image to a url location with the designated type format and EXIF metadata

     - Parameters:
     - url: file url to where the asset should be exported, this must be writable location
     - type: the UTI format to use when exporting the asset
     - compressionQuality: defines the compression quality of the export. This is only relevant for type formats that support a quality parameter. Ex: jpeg
     - metadata: the image metadata to save to file.
     */
    func writeToURL(url: NSURL, type: String, compressionQuality: Float = 0.9,  metadata: [String:AnyObject]? = nil) throws {
        let properties: [String:AnyObject] = [kCGImageDestinationLossyCompressionQuality as String: compressionQuality]
        var finalMetadata = metadata
        if metadata == nil {
            finalMetadata = [kCGImagePropertyOrientation as String: Int(metadataOrientation.rawValue)]
        }

        guard let destination = CGImageDestinationCreateWithURL(url, type, 1, nil),
              let imageRef = self.CGImage
        else {
                throw errorForCode(.FailedToWrite,
                    failureReason: NSLocalizedString("Unable to write image to file", comment: "Error reason to display when the writing of a image to a file fails")
                )
        }
        CGImageDestinationSetProperties(destination, properties)
        CGImageDestinationAddImage(destination, imageRef, finalMetadata)
        if (!CGImageDestinationFinalize(destination)) {
            throw errorForCode(.FailedToWrite,
                failureReason: NSLocalizedString("Unable to write image to file", comment: "Error reason to display when the writing of a image to a file fails")
            )
        }
    }

    /**
     Writes an image to a url location using the JPEG format.

     - Parameters:
     - url: file url to where the asset should be exported, this must be writable location
     */
    func writeJPEGToURL(url: NSURL) throws {
        let data = UIImageJPEGRepresentation(self, 0.9)
        try data?.writeToURL(url, options: NSDataWritingOptions())
    }

    // Converts the imageOrientation from the image to the CGImagePropertyOrientation to use in the file metadata.
    var metadataOrientation: CGImagePropertyOrientation {
        get {
            switch imageOrientation {
            case .Up: return CGImagePropertyOrientation.Up
            case .Down: return CGImagePropertyOrientation.Down
            case .Left: return CGImagePropertyOrientation.Left
            case .Right: return CGImagePropertyOrientation.Right
            case .UpMirrored: return CGImagePropertyOrientation.UpMirrored
            case .DownMirrored: return CGImagePropertyOrientation.DownMirrored
            case .LeftMirrored: return CGImagePropertyOrientation.LeftMirrored
            case .RightMirrored: return CGImagePropertyOrientation.RightMirrored
            }
        }
    }
}

extension UIImage: ExportableAsset
{
    func exportToURL(url: NSURL,
                     targetUTI: String,
                     maximumResolution: CGSize,
                     stripGeoLocation: Bool,
                     successHandler: SuccessHandler,
                     errorHandler: ErrorHandler)
    {
        var finalImage = self
        if (maximumResolution.width <= self.size.width || maximumResolution.height <= self.size.height) {
            finalImage = self.resizedImageWithContentMode(.ScaleAspectFit, bounds:maximumResolution, interpolationQuality:.High)
        }

        do {
            try finalImage.writeToURL(url, type:targetUTI, compressionQuality:0.9, metadata: nil)
            successHandler(resultingSize: finalImage.size)
        } catch let error as NSError {
            errorHandler(error: error)
        }
    }

    func exportThumbnailToURL(url: NSURL,
                              targetSize: CGSize,
                              synchronous: Bool,
                              successHandler: SuccessHandler,
                              errorHandler: ErrorHandler)
    {
        let thumbnail = self.resizedImageWithContentMode(.ScaleAspectFit, bounds:targetSize, interpolationQuality:.High)
        do {
            try self.writeToURL(url, type:kUTTypeJPEG as String, compressionQuality:0.9, metadata:nil)
            successHandler(resultingSize: thumbnail.size)
        } catch let error as NSError {
            errorHandler(error:error)
        }
    }

    func originalUTI() -> String? {
        return kUTTypeJPEG as String
    }

    var assetMediaType: MediaType {
        get {
            return .Image
        }
    }

    var defaultThumbnailUTI: String {
        get {
            return kUTTypeJPEG as String
        }
    }
}
