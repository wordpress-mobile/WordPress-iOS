import Foundation

@objc open class ReaderListTopic: ReaderAbstractTopic {
    @NSManaged open var isOwner: Bool
    @NSManaged open var isPublic: Bool
    @NSManaged open var listDescription: String
    @NSManaged open var listID: NSNumber
    @NSManaged open var owner: String
    @NSManaged open var slug: String

    override open class var TopicType: String {
        return "list"
    }
}
