import Foundation

extension PostHelper {
    @objc static let foreignIDKey = "wp_jp_foreign_id"

    static func mapDictionaryToMetadataItems(_ dictionary: [String: Any]) -> RemotePostMetadataItem? {
        let id = dictionary["id"]
        let value = dictionary["value"]
        return RemotePostMetadataItem(
            id: (id as? String) ?? (id as? NSNumber)?.stringValue,
            key: dictionary["key"] as? String,
            value: (value as? String) ?? (value as? UUID)?.uuidString
        )
    }
}
