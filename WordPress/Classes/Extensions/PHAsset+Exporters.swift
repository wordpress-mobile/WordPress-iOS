import Foundation
import Photos
import MobileCoreServices
import AVFoundation

extension PHAsset: ExportableAsset {

    public var assetMediaType: MediaType {
        get {
            if self.mediaType == .image {
                return .image
            } else if self.mediaType == .video {
                return .video
            }
            return .document
        }
     }

}
