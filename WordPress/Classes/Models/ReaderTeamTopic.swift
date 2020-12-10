import Foundation

@objc open class ReaderTeamTopic: ReaderAbstractTopic {
    @NSManaged open var slug: String

    override open class var TopicType: String {
        return "organization"
    }

    var shownTrackEvent: WPAnalyticsEvent {
        return slug == ReaderTeamTopic.a8cSlug ? .readerA8CShown : .readerP2Shown
    }

    static let a8cSlug = "a8c"
    static let p2Slug = "p2"
}
