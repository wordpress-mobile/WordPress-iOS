import Foundation
import ImageIO
import MobileCoreServices

extension UIImage {
    // MARK: - Error Handling
    enum ErrorCode: Int {
        case failedToWrite = 1
    }

    fileprivate func errorForCode(_ errorCode: ErrorCode, failureReason: String) -> NSError {
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
    func writeToURL(_ url: URL, type: String, compressionQuality: Float = 0.9,  metadata: [String: AnyObject]? = nil) throws {
        let properties: [String: AnyObject] = [kCGImageDestinationLossyCompressionQuality as String: compressionQuality as AnyObject]
        var finalMetadata = metadata
        if metadata == nil {
            finalMetadata = [kCGImagePropertyOrientation as String: Int(metadataOrientation.rawValue) as AnyObject]
        }

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type as CFString, 1, nil),
              let imageRef = self.cgImage
        else {
                throw errorForCode(.failedToWrite,
                    failureReason: NSLocalizedString("Unable to write image to file", comment: "Error reason to display when the writing of a image to a file fails")
                )
        }
        CGImageDestinationSetProperties(destination, properties as CFDictionary?)
        CGImageDestinationAddImage(destination, imageRef, finalMetadata as CFDictionary?)
        if (!CGImageDestinationFinalize(destination)) {
            throw errorForCode(.failedToWrite,
                failureReason: NSLocalizedString("Unable to write image to file", comment: "Error reason to display when the writing of a image to a file fails")
            )
        }
    }

    /**
     Writes an image to a url location using the JPEG format.

     - Parameters:
     - url: file url to where the asset should be exported, this must be writable location
     */
    func writeJPEGToURL(_ url: URL) throws {
        let data = UIImageJPEGRepresentation(self, 0.9)
        try data?.write(to: url, options: NSData.WritingOptions())
    }

    // Converts the imageOrientation from the image to the CGImagePropertyOrientation to use in the file metadata.
    var metadataOrientation: CGImagePropertyOrientation {
        get {
            switch imageOrientation {
            case .up: return CGImagePropertyOrientation.up
            case .down: return CGImagePropertyOrientation.down
            case .left: return CGImagePropertyOrientation.left
            case .right: return CGImagePropertyOrientation.right
            case .upMirrored: return CGImagePropertyOrientation.upMirrored
            case .downMirrored: return CGImagePropertyOrientation.downMirrored
            case .leftMirrored: return CGImagePropertyOrientation.leftMirrored
            case .rightMirrored: return CGImagePropertyOrientation.rightMirrored
            }
        }
    }
}

extension UIImage: ExportableAsset {
    func exportToURL(_ url: URL,
                     targetUTI: String,
                     maximumResolution: CGSize,
                     stripGeoLocation: Bool,
                     synchronous: Bool,
                     successHandler: @escaping SuccessHandler,
                     errorHandler: @escaping ErrorHandler) {
        var finalImage = self
        if (maximumResolution.width <= self.size.width || maximumResolution.height <= self.size.height) {
            finalImage = self.resizedImage(with: .scaleAspectFit, bounds: maximumResolution, interpolationQuality: .high)
        }

        do {
            try finalImage.writeToURL(url, type: targetUTI, compressionQuality: 0.9, metadata: nil)
            successHandler(finalImage.size)
        } catch let error as NSError {
            errorHandler(error)
        }
    }

    func exportThumbnailToURL(_ url: URL,
                              targetSize: CGSize,
                              synchronous: Bool,
                              successHandler: @escaping SuccessHandler,
                              errorHandler: @escaping ErrorHandler) {
        let thumbnail = self.resizedImage(with: .scaleAspectFit, bounds: targetSize, interpolationQuality: .high)
        do {
            try self.writeToURL(url, type: defaultThumbnailUTI as String, compressionQuality: 0.9, metadata: nil)
            successHandler((thumbnail?.size)!)
        } catch let error as NSError {
            errorHandler(error)
        }
    }

    func exportOriginalImage(_ toURL: URL, successHandler: @escaping SuccessHandler, errorHandler: @escaping ErrorHandler) {
        do {
            try self.writeToURL(toURL, type: originalUTI()!, compressionQuality: 1.0, metadata: nil)
            successHandler(self.size)
        } catch let error as NSError {
            errorHandler(error)
        }
    }

    func originalUTI() -> String? {
        return kUTTypeJPEG as String
    }

    var assetMediaType: MediaType {
        get {
            return .image
        }
    }

    var defaultThumbnailUTI: String {
        get {
            return kUTTypeJPEG as String
        }
    }
}
