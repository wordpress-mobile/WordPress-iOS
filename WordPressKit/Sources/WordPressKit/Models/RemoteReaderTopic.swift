import Foundation

@objcMembers public class RemoteReaderTopic: NSObject {

    public var isMenuItem: Bool = false
    public var isRecommended: Bool
    public var isSubscribed: Bool
    public var path: String?
    public var slug: String?
    public var title: String?
    public var topicDescription: String?
    public var topicID: NSNumber
    public var type: String?
    public var owner: String?
    public var organizationID: NSNumber

    /// Create `RemoteReaderTopic` with the supplied topics dictionary, ensuring expected keys are always present.
    ///
    /// - Parameters:
    ///   - topicDict: The topic `NSDictionary` to normalize.
    ///   - subscribed: Whether the current account subscribes to the topic.
    ///   - recommended: Whether the topic is recommended.
    public init(dictionary topicDict: NSDictionary, subscribed: Bool, recommended: Bool) {
        topicID = topicDict.number(forKey: topicDictionaryIDKey) ?? 0
        owner = topicDict.string(forKey: topicDictionaryOwnerKey)
        path = topicDict.string(forKey: topicDictionaryURLKey)?.lowercased()
        slug = topicDict.string(forKey: topicDictionarySlugKey)
        title = topicDict.string(forKey: topicDictionaryDisplayNameKey) ?? topicDict.string(forKey: topicDictionaryTitleKey)
        type = topicDict.string(forKey: topicDictionaryTypeKey)
        organizationID = topicDict.number(forKeyPath: topicDictionaryOrganizationIDKey) ?? 0
        isSubscribed = subscribed
        isRecommended = recommended
    }
}

private let topicDictionaryIDKey = "ID"
private let topicDictionaryOrganizationIDKey = "organization_id"
private let topicDictionaryOwnerKey = "owner"
private let topicDictionarySlugKey = "slug"
private let topicDictionaryTitleKey = "title"
private let topicDictionaryTypeKey = "type"
private let topicDictionaryDisplayNameKey = "display_name"
private let topicDictionaryURLKey = "URL"
