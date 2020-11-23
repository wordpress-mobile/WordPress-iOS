import Foundation

@objc class CommentAnalytics: NSObject{

    static func trackingContext() -> String {
        let screen = WPTabBarController.sharedInstance()?.currentlySelectedScreen() ?? "unknown"
        switch screen {
        case WPTabBarCurrentlySelectedScreenSites:
            return "sites"
        case WPTabBarCurrentlySelectedScreenReader:
            return "reader"
        case WPTabBarCurrentlySelectedScreenNotifications:
            return "notifications"
        default:
            return "unknown"
        }
    }

    static func defaultProperties(comment: Comment) -> [AnyHashable: Any] {
        return [
            "context": trackingContext(),
            "post_id": comment.postID.intValue,
            "comment_id": comment.commentID.intValue
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

}
