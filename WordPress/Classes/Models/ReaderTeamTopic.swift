import Foundation

@objc open class ReaderTeamTopic: ReaderAbstractTopic {
    @NSManaged open var slug: String

    override open class var TopicType: String {
        return "organization"
    }

    static let a8cSlug = "a8c"
    static let p2Slug = "p2"
}
