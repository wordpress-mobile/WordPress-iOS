import Foundation

@objc public class ReaderTagTopic : ReaderAbstractTopic
{
    @NSManaged var isRecommended: Bool
    @NSManaged var slug: String
    @NSManaged var tagID: NSNumber

    public class var TopicType: String {
        return "tag"
    }
}
