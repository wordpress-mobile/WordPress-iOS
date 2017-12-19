import Foundation
import Photos
import MobileCoreServices
import AVFoundation

extension PHAsset {

    public var uniformTypeIdentifier: String? {
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

    public var originalFilename: String? {
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

}
