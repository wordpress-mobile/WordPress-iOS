import Foundation


/// Mapping keys
private struct CodingKeys {
    static let sendPost = "send_posts"
    static let sendComments = "send_comments"
    static let postDeliveryFrequency = "post_delivery_frequency"
}


/// Site Info Post Subscription model
@objc public class RemoteReaderSiteInfoSubscriptionPost: NSObject {
    @objc public var sendPosts: Bool
    
    
    @objc required public init(dictionary: [String: Any]) {
        self.sendPosts = (dictionary[CodingKeys.sendPost] as? Bool) ?? false
        super.init()
    }
}


/// Site Info Email Subscription model
@objc public class RemoteReaderSiteInfoSubscriptionEmail: RemoteReaderSiteInfoSubscriptionPost {
    @objc public var sendComments: Bool
    @objc public var postDeliveryFrequency: String

    
    @objc required public init(dictionary: [String: Any]) {
        sendComments = (dictionary[CodingKeys.sendComments] as? Bool) ?? false
        postDeliveryFrequency = (dictionary[CodingKeys.postDeliveryFrequency] as? String) ?? ""
        super.init(dictionary: dictionary)
    }
}
