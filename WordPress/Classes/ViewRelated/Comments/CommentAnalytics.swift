import Foundation

@objc class CommentAnalytics: NSObject {

    struct Constants {
        static let sites = "sites"
        static let reader = "reader"
        static let notifications = "notifications"
        static let unknown = "unknown"
        static let context = "context"
    }

    static func trackingContext() -> String {
        let screen = WPTabBarController.sharedInstance()?.currentlySelectedScreen() ?? Constants.unknown
        switch screen {
        case WPTabBarCurrentlySelectedScreenSites:
            return Constants.sites
        case WPTabBarCurrentlySelectedScreenReader:
            return Constants.reader
        case WPTabBarCurrentlySelectedScreenNotifications:
            return Constants.notifications
        default:
            return Constants.unknown
        }
    }

    static func defaultProperties(comment: Comment) -> [AnyHashable: Any] {
        return [
            Constants.context: trackingContext(),
            WPAppAnalyticsKeyPostID: comment.postID,
            WPAppAnalyticsKeyCommentID: comment.commentID
        ]
    }

    @objc static func trackCommentViewed(comment: Comment) {
        trackCommentEvent(comment: comment, event: .commentViewed)
    }

    @objc static func trackCommentEditorOpened(comment: Comment) {
        trackCommentEvent(comment: comment, event: .commentEditorOpened)
    }

    @objc static func trackCommentEdited(comment: Comment) {
        trackCommentEvent(comment: comment, event: .commentEdited)
    }

    @objc static func trackCommentApproved(comment: Comment) {
        trackCommentEvent(comment: comment, event: .commentApproved)
    }

    @objc static func trackCommentUnApproved(comment: Comment) {
        trackCommentEvent(comment: comment, event: .commentUnApproved)
    }

    @objc static func trackCommentTrashed(comment: Comment) {
        trackCommentEvent(comment: comment, event: .commentTrashed)
    }

    @objc static func trackCommentSpammed(comment: Comment) {
        trackCommentEvent(comment: comment, event: .commentSpammed)
    }

    @objc static func trackCommentLiked(comment: Comment) {
        trackCommentEvent(comment: comment, event: .commentLiked)
    }

    @objc static func trackCommentUnLiked(comment: Comment) {
        trackCommentEvent(comment: comment, event: .commentUnliked)
    }

    @objc static func trackCommentRepliedTo(comment: Comment) {
        trackCommentEvent(comment: comment, event: .commentRepliedTo)
    }

    private static func trackCommentEvent(comment: Comment, event: WPAnalyticsEvent) {
        let properties = defaultProperties(comment: comment)

        guard let blog = comment.blog else {
            WPAnalytics.track(event, properties: properties)
            return
        }

        WPAnalytics.track(event, properties: properties, blog: blog)
    }

    static func trackCommentEditorOpened(block: FormattableCommentContent) {
        WPAnalytics.track(.commentEditorOpened, properties: [
            Constants.context: CommentAnalytics.trackingContext(),
            WPAppAnalyticsKeyBlogID: block.metaSiteID?.intValue ?? 0,
            WPAppAnalyticsKeyCommentID: block.metaCommentID?.intValue ?? 0
        ])
    }

    static func trackCommentEdited(block: FormattableCommentContent) {
        WPAnalytics.track(.commentEdited, properties: [
            Constants.context: CommentAnalytics.trackingContext(),
            WPAppAnalyticsKeyBlogID: block.metaSiteID?.intValue ?? 0,
            WPAppAnalyticsKeyCommentID: block.metaCommentID?.intValue ?? 0
        ])
    }

}
