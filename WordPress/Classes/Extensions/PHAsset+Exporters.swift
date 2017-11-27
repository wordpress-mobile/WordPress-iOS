import Foundation
import Photos
import MobileCoreServices
import AVFoundation

extension PHAsset: ExportableAsset {

    var defaultThumbnailUTI: String {
        get {
            return kUTTypeJPEG as String
        }
    }

    var assetMediaType: MediaType {
        get {
            if self.mediaType == .image {
                return .image
            } else if self.mediaType == .video {
                /** HACK: Sergio Estevao (2015-11-09): We ignore allowsFileTypes for videos in WP.com
                 because we have an exception on the server for mobile that allows video uploads event
                 if videopress is not enabled.
                 */
                return .video
            }
            return .document
        }
    }

    func originalUTI() -> String? {
        let resources = PHAssetResource.assetResources(for: self)
        var types: [PHAssetResourceType.RawValue] = []
        if mediaType == PHAssetMediaType.image {
            types = [PHAssetResourceType.photo.rawValue]
        } else if mediaType == PHAssetMediaType.video {
            types = [PHAssetResourceType.video.rawValue]
        }
        for resource in resources {
            if types.contains(resource.type.rawValue) {
                return resource.uniformTypeIdentifier
            }
        }
        return nil
    }

    @objc func originalFilename() -> String? {
        let resources = PHAssetResource.assetResources(for: self)
        var types: [PHAssetResourceType.RawValue] = []
        if mediaType == PHAssetMediaType.image {
            types = [PHAssetResourceType.photo.rawValue]
        } else if mediaType == PHAssetMediaType.video {
            types = [PHAssetResourceType.video.rawValue]
        }
        for resource in resources {
            if types.contains(resource.type.rawValue) {
                return resource.originalFilename
            }
        }
        return nil
    }

    var mediaName: String? {
        return originalFilename()
    }
}
