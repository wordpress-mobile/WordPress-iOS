import Foundation

@objc open class ReaderTagTopic: ReaderAbstractTopic {
    @NSManaged open var isRecommended: Bool
    @NSManaged open var slug: String
    @NSManaged open var tagID: NSNumber
    @NSManaged open var cards: NSOrderedSet?

    override open class var TopicType: String {
        return "tag"
    }

    // MARK: - Computed Properties

    /// The `slug` property is URL encoded. Use this property for display instead.
    public var slugForDisplay: String? {
        return slug.removingPercentEncoding
    }

    // MARK: - Logged Out Helpers

    /// The tagID used if an interest was added locally and not sync'd with the server
    public class var loggedOutTagID: NSNumber {
        return NSNotFound as NSNumber
    }

    /// Creates a new ReaderTagTopic object from a RemoteReaderInterest
    convenience public init(remoteInterest: RemoteReaderInterest, context: NSManagedObjectContext, isFollowing: Bool = false) {
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
    public class func createOrUpdateIfNeeded(from remoteInterest: RemoteReaderInterest, context: NSManagedObjectContext) -> ReaderTagTopic {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.classNameWithoutNamespaces())
        fetchRequest.predicate = NSPredicate(format: "slug = %@", remoteInterest.slug)
        let topics = try? context.fetch(fetchRequest) as? [ReaderTagTopic]

        guard let topic = topics?.first else {
            return ReaderTagTopic(remoteInterest: remoteInterest, context: context)
        }

        topic.title = remoteInterest.title

        return topic
    }

    public var formattedTitle: String {
        title.split(separator: "-").map(\.capitalized).joined(separator: " ")
    }

    /// Convenience method to update the tag's `following` state and also updates `showInMenu`.
    @objc public func toggleFollowing(_ isFollowing: Bool) {
        following = isFollowing
        showInMenu = (following || isRecommended)
    }
}

public extension ReaderTagTopic {
    static let dailyPromptTag = "dailyprompt"
}
