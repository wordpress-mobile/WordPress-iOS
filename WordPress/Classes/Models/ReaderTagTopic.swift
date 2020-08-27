import Foundation

@objc open class ReaderTagTopic: ReaderAbstractTopic {
    @NSManaged open var isRecommended: Bool
    @NSManaged open var slug: String
    @NSManaged open var tagID: NSNumber
    @NSManaged open var cards: NSOrderedSet?

    override open class var TopicType: String {
        return "tag"
    }

    // MARK: - Logged Out Helpers

    /// The tagID used if an interest was added locally and not sync'd with the server
    class var loggedOutTagID: NSNumber {
        return NSNotFound as NSNumber
    }

    /// Creates a new ReaderTagTopic object from a RemoteReaderInterest
    convenience init(remoteInterest: RemoteReaderInterest, context: NSManagedObjectContext, isFollowing: Bool = false) {
        self.init(context: context)

        title = remoteInterest.title
        slug = remoteInterest.slug
        tagID = Self.loggedOutTagID
        type = Self.TopicType
        following = isFollowing
        showInMenu = true
    }

    /// Returns an existing ReaderTagTopic or creates a new one based on remote interest
    /// If an existing topic is returned, the title will be updated with the remote interest
    class func createOrUpdateIfNeeded(from remoteInterest: RemoteReaderInterest, context: NSManagedObjectContext) -> ReaderTagTopic {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.classNameWithoutNamespaces())
        fetchRequest.predicate = NSPredicate(format: "slug = %@", remoteInterest.slug)
        let topics = try? context.fetch(fetchRequest) as? [ReaderTagTopic]

        guard let topic = topics?.first else {
            return ReaderTagTopic(remoteInterest: remoteInterest, context: context)
        }

        topic.title = remoteInterest.title

        return topic
    }
}
