import Foundation
import NSObject_SafeExpectations

// Site Topic Keys
private let SiteDictionaryFeedIDKey = "feed_ID"
private let SiteDictionaryFeedURLKey = "feed_URL"
private let SiteDictionaryFollowingKey = "is_following"
private let SiteDictionaryJetpackKey = "is_jetpack"
private let SiteDictionaryOrganizationID = "organization_id"
private let SiteDictionaryPrivateKey = "is_private"
private let SiteDictionaryVisibleKey = "visible"
private let SiteDictionaryPostCountKey = "post_count"
private let SiteDictionaryIconPathKey = "icon.img"
private let SiteDictionaryDescriptionKey = "description"
private let SiteDictionaryIDKey = "ID"
private let SiteDictionaryNameKey = "name"
private let SiteDictionaryURLKey = "URL"
private let SiteDictionarySubscriptionsKey = "subscribers_count"
private let SiteDictionarySubscriptionKey = "subscription"
private let SiteDictionaryUnseenCountKey = "unseen_count"

// Subscription keys
private let SubscriptionDeliveryMethodsKey = "delivery_methods"

// Delivery methods keys
private let DeliveryMethodEmailKey = "email"
private let DeliveryMethodNotificationKey = "notification"

@objcMembers public class RemoteReaderSiteInfo: NSObject {
    public var feedID: NSNumber?
    public var feedURL: String?
    public var isFollowing: Bool = false
    public var isJetpack: Bool = false
    public var isPrivate: Bool = false
    public var isVisible: Bool = false
    public var organizationID: NSNumber?
    public var postCount: NSNumber?
    public var siteBlavatar: String?
    public var siteDescription: String?
    public var siteID: NSNumber?
    public var siteName: String?
    public var siteURL: String?
    public var subscriberCount: NSNumber?
    public var unseenCount: NSNumber?
    public var postsEndpoint: String?
    public var endpointPath: String?

    public var postSubscription: RemoteReaderSiteInfoSubscriptionPost?
    public var emailSubscription: RemoteReaderSiteInfoSubscriptionEmail?

    public class func siteInfo(forSiteResponse response: NSDictionary, isFeed: Bool) -> RemoteReaderSiteInfo {
        if isFeed {
            return siteInfo(forFeedResponse: response)
        }

        let siteInfo = RemoteReaderSiteInfo()
        siteInfo.feedID = response.number(forKey: SiteDictionaryFeedIDKey)
        siteInfo.feedURL = response.string(forKey: SiteDictionaryFeedURLKey)
        siteInfo.isFollowing = response.number(forKey: SiteDictionaryFollowingKey)?.boolValue ?? false
        siteInfo.isJetpack = response.number(forKey: SiteDictionaryJetpackKey)?.boolValue ?? false
        siteInfo.isPrivate = response.number(forKey: SiteDictionaryPrivateKey)?.boolValue ?? false
        siteInfo.isVisible = response.number(forKey: SiteDictionaryVisibleKey)?.boolValue ?? false
        siteInfo.organizationID = response.number(forKey: SiteDictionaryOrganizationID) ?? 0
        siteInfo.postCount = response.number(forKey: SiteDictionaryPostCountKey)
        siteInfo.siteBlavatar = response.string(forKeyPath: SiteDictionaryIconPathKey)
        siteInfo.siteDescription = response.string(forKey: SiteDictionaryDescriptionKey)
        siteInfo.siteID = response.number(forKey: SiteDictionaryIDKey)
        siteInfo.siteName = response.string(forKey: SiteDictionaryNameKey)
        siteInfo.siteURL = response.string(forKey: SiteDictionaryURLKey)
        siteInfo.subscriberCount = response.number(forKey: SiteDictionarySubscriptionsKey) ?? 0
        siteInfo.unseenCount = response.number(forKey: SiteDictionaryUnseenCountKey) ?? 0

        if (siteInfo.siteName?.count ?? 0) == 0,
           let siteURLString = siteInfo.siteURL,
           let siteURL = URL(string: siteURLString) {
            siteInfo.siteName = siteURL.host
        }

        siteInfo.endpointPath = "read/sites/\(siteInfo.siteID ?? 0)/posts/"

        if let subscription = response[SiteDictionarySubscriptionKey] as? NSDictionary {
            siteInfo.postSubscription = postSubscription(forSubscription: subscription)
            siteInfo.emailSubscription = emailSubscription(forSubscription: subscription)
        }

        return siteInfo
    }

}

private extension RemoteReaderSiteInfo {
    class func siteInfo(forFeedResponse response: NSDictionary) -> RemoteReaderSiteInfo {
        let siteInfo = RemoteReaderSiteInfo()
        siteInfo.feedID = response.number(forKey: SiteDictionaryFeedIDKey)
        siteInfo.feedURL = response.string(forKey: SiteDictionaryFeedURLKey)
        siteInfo.isFollowing = response.number(forKey: SiteDictionaryFollowingKey)?.boolValue ?? false
        siteInfo.isJetpack = false
        siteInfo.isPrivate = false
        siteInfo.isVisible = true
        siteInfo.postCount = 0
        siteInfo.siteBlavatar = ""
        siteInfo.siteDescription = ""
        siteInfo.siteID = 0
        siteInfo.siteName = response.string(forKey: SiteDictionaryNameKey)
        siteInfo.siteURL = response.string(forKey: SiteDictionaryURLKey)
        siteInfo.subscriberCount = response.number(forKey: SiteDictionarySubscriptionsKey) ?? 0

        if (siteInfo.siteName?.count ?? 0) == 0,
           let siteURLString = siteInfo.siteURL,
           let siteURL = URL(string: siteURLString) {
            siteInfo.siteName = siteURL.host
        }

        siteInfo.endpointPath = "read/feed/\(siteInfo.feedID ?? 0)/posts/"

        return siteInfo
    }

    /// Generate an Site Info Post Subscription object
    ///
    /// - Parameter subscription A dictionary object for the site subscription
    /// - Returns A nullable Site Info Post Subscription
    class func postSubscription(forSubscription subscription: NSDictionary) -> RemoteReaderSiteInfoSubscriptionPost? {
        guard subscription.wp_isValidObject() else {
            return nil
        }

        guard let deliveryMethod = subscription[SubscriptionDeliveryMethodsKey] as? [String: Any],
              let method = deliveryMethod[DeliveryMethodNotificationKey] as? [String: Any]
        else {
            return nil
        }

        return RemoteReaderSiteInfoSubscriptionPost(dictionary: method)
    }

    /// Generate an Site Info Email Subscription object
    ///
    /// - Parameter subscription A dictionary object for the site subscription
    /// - Returns A nullable Site Info Email Subscription
    class func emailSubscription(forSubscription subscription: NSDictionary) -> RemoteReaderSiteInfoSubscriptionEmail? {
        guard subscription.wp_isValidObject() else {
            return nil
        }

        guard let delieveryMethod = subscription[SubscriptionDeliveryMethodsKey] as? [String: Any],
              let method = delieveryMethod[DeliveryMethodEmailKey] as? [String: Any]
        else {
            return nil
        }

        return RemoteReaderSiteInfoSubscriptionEmail(dictionary: method)
    }
}
