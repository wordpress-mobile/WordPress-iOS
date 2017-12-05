import Foundation
import Photos
import MobileCoreServices
import AVFoundation

extension NSURL: ExportableAsset {

    public var assetMediaType: MediaType {
        get {
            let url = self as URL
            if url.isImage {
                return .image
            } else if url.isVideo {
                return .video
            }
            return .document
        }
    }

}
