import Foundation

@objc
extension RemotePost {
    var foreignID: String? {
        let metadataItems = metadata.compactMap { value -> RemotePostMetadataItem? in
            guard let dictionary = value as? [String: Any] else {
                return nil
            }
            let id = dictionary["id"]

            return RemotePostMetadataItem(
                id: (id as? String) ?? (id as? NSNumber)?.stringValue,
                key: dictionary["key"] as? String,
                value: dictionary["value"] as? String
            )
        }
        return metadataItems.first { $0.key == BasePost.foreignIDKey }?.value
    }
}

@objc
extension BasePost {
    static let foreignIDKey = "wp_jp_foreign_id"
}
