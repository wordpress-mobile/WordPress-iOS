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
private let SiteDictionaryBlogIDKey = "blog_ID"
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

/// Parsed from an API response on one thread, then handed to callers without further
/// mutation, so crossing a task boundary is safe despite the mutable properties.
@objcMembers public class RemoteReaderSiteInfo: NSObject, @unchecked Sendable {
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

        siteInfo.fillEmptyNameWithHost()

        siteInfo.endpointPath = "read/sites/\(siteInfo.siteID ?? 0)/posts/"

        if let subscription = response[SiteDictionarySubscriptionKey] as? NSDictionary {
            siteInfo.postSubscription = postSubscription(forSubscription: subscription)
            siteInfo.emailSubscription = emailSubscription(forSubscription: subscription)
        }

        return siteInfo
    }

    /// Creates site info for an entry of the `read/following/mine?meta=site,feed` response.
    ///
    /// The entry's `meta.data.site` or `meta.data.feed` is preferred. Either meta can be an error object, for
    /// example for a private site the user can no longer read. The feed meta can also have an empty name and URL
    /// when the server has not read the feed: a feed subscribed moments ago, or a site that was deleted. The
    /// entry's own fields fill those gaps, so every followed site has a feed ID, a URL, and a name.
    public class func siteInfo(forFollowedSiteResponse response: NSDictionary) -> RemoteReaderSiteInfo {
        let site = response.object(forKeyPath: "meta.data.site") as? NSDictionary
        let feed = response.object(forKeyPath: "meta.data.feed") as? NSDictionary
        let siteInfo: RemoteReaderSiteInfo
        if let site, site[SiteDictionaryIDKey] != nil {
            siteInfo = self.siteInfo(forSiteResponse: site, isFeed: false)
        } else if let feed, feed[SiteDictionaryFeedIDKey] != nil {
            siteInfo = self.siteInfo(forFeedResponse: feed)
        } else {
            // The entry has the feed keys (`feed_ID`, `feed_URL`, `name`, `URL`) at its top level.
            siteInfo = self.siteInfo(forFeedResponse: response)
        }

        // A WordPress.com site keeps its site ID and endpoint when its site meta is an error object. Otherwise the
        // topic saved under `read/sites/<blogID>/posts/` would get a duplicate under the feed endpoint. External
        // feeds have a `blog_ID` of 0, "0" or false, and stay feeds.
        if (siteInfo.siteID?.intValue ?? 0) == 0,
           let blogID = response.number(forKey: SiteDictionaryBlogIDKey), blogID.intValue != 0 {
            siteInfo.siteID = blogID
            siteInfo.endpointPath = "read/sites/\(blogID)/posts/"
        }

        // Every entry of this response is followed, including those whose meta is an error object.
        siteInfo.isFollowing = true

        if siteInfo.siteURL?.isEmpty ?? true {
            siteInfo.siteURL = response.string(forKey: SiteDictionaryURLKey)
        }
        if siteInfo.siteName?.isEmpty ?? true {
            siteInfo.siteName = response.string(forKey: SiteDictionaryNameKey)
            siteInfo.fillEmptyNameWithHost()
        }

        return siteInfo
    }
}

private extension RemoteReaderSiteInfo {
    func fillEmptyNameWithHost() {
        guard siteName?.isEmpty ?? true, let siteURL, let url = URL(string: siteURL) else {
            return
        }
        siteName = url.host
    }

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

        siteInfo.fillEmptyNameWithHost()

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
