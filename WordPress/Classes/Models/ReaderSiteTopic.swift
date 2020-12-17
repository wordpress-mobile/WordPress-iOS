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
    @NSManaged open var organizationID: Int
    @NSManaged open var postCount: NSNumber
    @NSManaged open var siteBlavatar: String
    @NSManaged open var siteDescription: String
    @NSManaged open var siteID: NSNumber
    @NSManaged open var siteURL: String
    @NSManaged open var subscriberCount: NSNumber
    @NSManaged open var unseenCount: Int
    @NSManaged open var cards: NSOrderedSet?

    override open class var TopicType: String {
        return "site"
    }

    @objc open var isExternal: Bool {
        get {
            return siteID.intValue == 0
        }
    }

    var organizationType: SiteOrganizationType {
        SiteOrganizationType(rawValue: organizationID) ?? .none
    }

    var isP2Type: Bool {
        return organizationType == .p2 || organizationType == .automattic
    }

    @objc open var blogNameToDisplay: String {
        return posts.first?.blogNameForDisplay() ?? title
    }

    @objc open var isSubscribedForPostNotifications: Bool {
        return postSubscription?.sendPosts ?? false
    }


    /// Creates a new ReaderTagTopic object from a RemoteReaderInterest
    convenience init(remoteInfo: RemoteReaderSiteInfo, context: NSManagedObjectContext) {
        self.init(context: context)

        feedID = remoteInfo.feedID ?? 0
        feedURL = remoteInfo.feedURL ?? ""
        following = remoteInfo.isFollowing
        isJetpack = remoteInfo.isJetpack
        isPrivate = remoteInfo.isPrivate
        isVisible = remoteInfo.isVisible
        organizationID = remoteInfo.organizationID.intValue
        path = remoteInfo.postsEndpoint ?? remoteInfo.endpointPath ?? ""
        postCount = remoteInfo.postCount ?? 0
        showInMenu = false
        siteBlavatar = remoteInfo.siteBlavatar ?? ""
        siteDescription = remoteInfo.siteDescription ?? ""
        siteID = remoteInfo.siteID ?? 0
        siteURL = remoteInfo.siteURL ?? ""
        subscriberCount = remoteInfo.subscriberCount ?? 0
        title = remoteInfo.siteName ?? ""
        type = Self.TopicType

        postSubscription = ReaderSiteInfoSubscriptionPost.createOrUpdate(from: remoteInfo, topic: self, context: context)
        emailSubscription = ReaderSiteInfoSubscriptionEmail.createOrUpdate(from: remoteInfo, topic: self, context: context)
    }

    class func createIfNeeded(from remoteInfo: RemoteReaderSiteInfo, context: NSManagedObjectContext) -> ReaderSiteTopic {
        guard let path = remoteInfo.postsEndpoint ?? remoteInfo.endpointPath else {
            return ReaderSiteTopic(remoteInfo: remoteInfo, context: context)
        }

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderAbstractTopic.classNameWithoutNamespaces())
        fetchRequest.predicate = NSPredicate(format: "path = %@ OR path ENDSWITH %@", path, path)

        let topics = try? context.fetch(fetchRequest) as? [ReaderSiteTopic]

        guard let topic = topics?.first else {
            return ReaderSiteTopic(remoteInfo: remoteInfo, context: context)
        }

        return topic
    }
}
