import Foundation

@objc
extension RemotePost {
    var foreignID: String? {
        let metadataItems = metadata.compactMap { value -> RemotePostMetadataItem? in
            guard let dictionary = value as? [String: Any] else {
                assertionFailure("Unexpected value: \(value)")
                return nil
            }
            return PostHelper.mapDictionaryToMetadataItems(dictionary)
        }
        return metadataItems.first { $0.key == PostHelper.foreignIDKey }?.value
    }
}
