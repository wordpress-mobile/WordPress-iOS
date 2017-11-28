import Foundation
import Photos
import MobileCoreServices
import AVFoundation

extension PHAsset: ExportableAsset {

    public var defaultThumbnailUTI: String {
        get {
            return kUTTypeJPEG as String
        }
    }

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

    public func originalUTI() -> String? {
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

    public var mediaName: String? {
        return originalFilename()
    }
}
