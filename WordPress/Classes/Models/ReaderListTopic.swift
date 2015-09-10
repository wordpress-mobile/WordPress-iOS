import Foundation

@objc public class ReaderListTopic : ReaderAbstractTopic
{
    @NSManaged public var isOwner: Bool
    @NSManaged public var isPublic: Bool
    @NSManaged public var listDescription: String
    @NSManaged public var listID:NSNumber
    @NSManaged public var owner: String
    @NSManaged public var slug:String

    override public class var TopicType: String {
        return "list"
    }
}
