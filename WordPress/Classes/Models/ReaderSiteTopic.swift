import Foundation

@objc open class ReaderSiteTopic: ReaderAbstractTopic {
    // Relations
    @NSManaged open var postSubscription: ReaderSiteInfoSubscriptionPost?
    @NSManaged open var emailSubscription: ReaderSiteInfoSubscriptionEmail?
    
    // Properties
    @NSManaged open var feedID: NSNumber
    @NSManaged open var feedURL: String
    @NSManaged open var isJetpack: Bool
    @NSManaged open var isPrivate: Bool
    @NSManaged open var isVisible: Bool
    @NSManaged open var postCount: NSNumber
    @NSManaged open var siteBlavatar: String
    @NSManaged open var siteDescription: String
    @NSManaged open var siteID: NSNumber
    @NSManaged open var siteURL: String
    @NSManaged open var subscriberCount: NSNumber

    override open class var TopicType: String {
        return "site"
    }

    @objc open var isExternal: Bool {
        get {
            return siteID.intValue == 0
        }
    }
    
    
    //MARK: - Public methods
    
    @objc public func blogNameToDisplay() -> String {
        return posts.first?.blogNameForDisplay() ?? title
    }
    
    @objc public func isSubscribedForPostNotifications() -> Bool {
        return postSubscription?.sendPosts ?? false
    }
}
