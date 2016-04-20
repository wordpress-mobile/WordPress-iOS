import Foundation

@objc public class ReaderTagTopic : ReaderAbstractTopic
{
    @NSManaged public var isRecommended: Bool
    @NSManaged public var slug: String
    @NSManaged public var tagID: NSNumber

    override public class var TopicType: String {
        return "tag"
    }
}
