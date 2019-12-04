import Foundation
import UIKit

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
    @objc func writeToURL(_ url: URL, type: String, compressionQuality: Float = 0.9, metadata: [String: AnyObject]? = nil) throws {
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
        if !CGImageDestinationFinalize(destination) {
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
    @objc func writeJPEGToURL(_ url: URL) throws {
        let data = self.jpegData(compressionQuality: 0.9)
        try data?.write(to: url, options: NSData.WritingOptions())
    }

    // Converts the imageOrientation from the image to the CGImagePropertyOrientation to use in the file metadata.
    @objc var metadataOrientation: CGImagePropertyOrientation {
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
            @unknown default:
                fatalError()
            }
        }
    }
}
