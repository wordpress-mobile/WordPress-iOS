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
        
        guard let destination = CGImageDestinationCreateWithURL(url, type, 1, nil),
              let imageRef = self.CGImage
        else {
                throw errorForCode(.FailedToWrite,
                    failureReason: NSLocalizedString("Unable to write image to file", comment: "Error reason to display when the writing of a image to a file fails")
                )
        }
        CGImageDestinationSetProperties(destination, properties);
        CGImageDestinationAddImage(destination, imageRef, metadata);
        if (!CGImageDestinationFinalize(destination)) {
            throw errorForCode(.FailedToWrite,
                failureReason: NSLocalizedString("Unable to write image to file", comment: "Error reason to display when the writing of a image to a file fails")
            )
        }
    }
}