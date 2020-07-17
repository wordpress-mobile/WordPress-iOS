import Foundation

@objc open class ReaderTagTopic: ReaderAbstractTopic {
    @NSManaged open var isRecommended: Bool
    @NSManaged open var slug: String
    @NSManaged open var tagID: NSNumber

    override open class var TopicType: String {
        return "tag"
    }

    // MARK: - Logged Out Helpers

    /// The tagID used if an interest was added locally and not sync'd with the server
    class var loggedOutTagID: NSNumber {
        return NSNotFound as NSNumber
    }

    /// If an interest was added while the user is not logged into a WP.com account
    /// The tagID will be 0
    @objc var wasAddedWhileLoggedOut: Bool {
        return tagID == Self.loggedOutTagID
    }

    /// Creates a new ReaderTagTopic object from a RemoteReaderInterest
    convenience init?(remoteInterest: RemoteReaderInterest, context: NSManagedObjectContext) {
        self.init(context: context)

        title = remoteInterest.title
        slug = remoteInterest.slug
        tagID = Self.loggedOutTagID
        type = Self.TopicType
        following = true
        showInMenu = true
    }
}
