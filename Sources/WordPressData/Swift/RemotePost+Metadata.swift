import Foundation
import WordPressShared

@objc
public extension RemotePost {
    var foreignID: UUID? {
        guard let metadata else {
            return nil
        }
        let metadataItems = metadata.compactMap { value -> RemotePostMetadataItem? in
            guard let dictionary = value as? [String: Any] else {
                wpAssertionFailure("Unexpected value", userInfo: [
                    "value": value
                ])
                return nil
            }
            return PostHelper.mapDictionaryToMetadataItems(dictionary)
        }
        guard let value = metadataItems.first(where: { $0.key == PostHelper.foreignIDKey })?.value else {
            return nil
        }
        return UUID(uuidString: value)
    }
}
