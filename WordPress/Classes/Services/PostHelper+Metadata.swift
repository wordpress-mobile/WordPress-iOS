import Foundation

extension PostHelper {
    @objc static let foreignIDKey = "wp_jp_foreign_id"

    static func mapDictionaryToMetadataItems(_ dictionary: [String: Any]) -> RemotePostMetadataItem? {
        let id = dictionary["id"]
        return RemotePostMetadataItem(
            id: (id as? String) ?? (id as? NSNumber)?.stringValue,
            key: dictionary["key"] as? String,
            value: dictionary["value"] as? String
        )
    }
}
