import Foundation

@objc open class ReaderTagTopic: ReaderAbstractTopic {
    @NSManaged open var isRecommended: Bool
    @NSManaged open var slug: String
    @NSManaged open var tagID: NSNumber
    @NSManaged open var card: NSOrderedSet?

    override open class var TopicType: String {
        return "tag"
    }

    // MARK: - Logged Out Helpers

    /// The tagID used if an interest was added locally and not sync'd with the server
    class var loggedOutTagID: NSNumber {
        return NSNotFound as NSNumber
    }

    /// If an interest was followed while the user is not logged into a WP.com account
    /// The tagID will be 0
    @objc var wasFollowedWhileLoggedOut: Bool {
        return tagID == Self.loggedOutTagID && following
    }

    /// Creates a new ReaderTagTopic object from a RemoteReaderInterest
    convenience init(remoteInterest: RemoteReaderInterest, context: NSManagedObjectContext) {
        self.init(context: context)

        title = remoteInterest.title
        slug = remoteInterest.slug
        tagID = Self.loggedOutTagID
        type = Self.TopicType
        following = true
        showInMenu = true
    }

    /// Returns an existent ReaderTagTopic or create a new one based on remote interest
    class func createIfNeeded(from remoteInterest: RemoteReaderInterest, context: NSManagedObjectContext) -> ReaderTagTopic {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.classNameWithoutNamespaces())
        fetchRequest.predicate = NSPredicate(format: "slug = %@", remoteInterest.slug)
        let topics = try? context.fetch(fetchRequest) as? [ReaderTagTopic]
        return topics?.first ?? ReaderTagTopic(remoteInterest: remoteInterest, context: context)
    }
}
