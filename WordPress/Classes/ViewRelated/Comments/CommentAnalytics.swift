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
            WPAppAnalyticsKeyPostID: comment.postID.intValue,
            WPAppAnalyticsKeyCommentID: comment.commentID.intValue
        ]
    }

    @objc static func trackCommentViewed(comment: Comment) {
        let properties = defaultProperties(comment: comment)
        WPAnalytics.track(.commentViewed, properties: properties, blog: comment.blog)
    }

    @objc static func trackCommentEditorOpened(comment: Comment) {
        let properties = defaultProperties(comment: comment)
        WPAnalytics.track(.commentEditorOpened, properties: properties, blog: comment.blog)
    }

    @objc static func trackCommentEdited(comment: Comment) {
        let properties = defaultProperties(comment: comment)
        WPAnalytics.track(.commentEdited, properties: properties, blog: comment.blog)
    }

    @objc static func trackCommentApproved(comment: Comment) {
        let properties = defaultProperties(comment: comment)
        WPAnalytics.track(.commentApproved, properties: properties, blog: comment.blog)
    }

    @objc static func trackCommentUnApproved(comment: Comment) {
        let properties = defaultProperties(comment: comment)
        WPAnalytics.track(.commentUnApproved, properties: properties, blog: comment.blog)
    }

    @objc static func trackCommentTrashed(comment: Comment) {
        let properties = defaultProperties(comment: comment)
        WPAnalytics.track(.commentTrashed, properties: properties, blog: comment.blog)
    }

    @objc static func trackCommentSpammed(comment: Comment) {
        let properties = defaultProperties(comment: comment)
        WPAnalytics.track(.commentSpammed, properties: properties, blog: comment.blog)
    }

    @objc static func trackCommentLiked(comment: Comment) {
        let properties = defaultProperties(comment: comment)
        WPAnalytics.track(.commentLiked, properties: properties, blog: comment.blog)
    }

    @objc static func trackCommentUnLiked(comment: Comment) {
        let properties = defaultProperties(comment: comment)
        WPAnalytics.track(.commentUnliked, properties: properties, blog: comment.blog)
    }

    @objc static func trackCommentRepliedTo(comment: Comment) {
        let properties = defaultProperties(comment: comment)
        WPAnalytics.track(.commentRepliedTo, properties: properties, blog: comment.blog)
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
