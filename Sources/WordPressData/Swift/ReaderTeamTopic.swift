import Foundation

@objc(ReaderTeamTopic)
open class ReaderTeamTopic: ReaderAbstractTopic {
    @NSManaged open var slug: String
    @NSManaged open var organizationID: Int

    override open class var TopicType: String {
        return "organization"
    }

    public var organizationType: SiteOrganizationType {
        return SiteOrganizationType(rawValue: organizationID) ?? .none
    }

    public static let a8cSlug = "a8c"
    public static let p2Slug = "p2"
}
