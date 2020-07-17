import Foundation

@objc open class ReaderTagTopic: ReaderAbstractTopic {
    @NSManaged open var isRecommended: Bool
    @NSManaged open var slug: String
    @NSManaged open var tagID: NSNumber

    override open class var TopicType: String {
        return "tag"
    }

    /// If an interest was added while the user is not logged into a WP.com account
    /// The tagID will be 0
    @objc var wasAddedWhileLoggedOut: Bool {
        return tagID == 0
    }
}
