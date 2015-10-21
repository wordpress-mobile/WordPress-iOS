import Foundation

@objc public class ReaderSiteTopic: ReaderAbstractTopic
{
    @NSManaged public var feedID: NSNumber
    @NSManaged public var isJetpack: Bool
    @NSManaged public var isPrivate: Bool
    @NSManaged public var isVisible: Bool
    @NSManaged public var postCount: NSNumber
    @NSManaged public var siteBlavatar: String
    @NSManaged public var siteDescription: String
    @NSManaged public var siteID: NSNumber
    @NSManaged public var siteURL: String
    @NSManaged public var subscriberCount: NSNumber

    override public class var TopicType: String {
        return "site"
    }

    public var isExternal: Bool {
        get {
            return (feedID.integerValue > 0)
        }
    }
}
