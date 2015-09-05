import Foundation

@objc public class ReaderSiteTopic: ReaderAbstractTopic
{
    @NSManaged var feedID: NSNumber
    @NSManaged var isJetpack: Bool
    @NSManaged var isPrivate: Bool
    @NSManaged var isVisible: Bool
    @NSManaged var postCount: NSNumber
    @NSManaged var siteBlavatar: String
    @NSManaged var siteDescription: String
    @NSManaged var siteID: NSNumber
    @NSManaged var siteURL: String
    @NSManaged var subscriberCount: NSNumber

}
