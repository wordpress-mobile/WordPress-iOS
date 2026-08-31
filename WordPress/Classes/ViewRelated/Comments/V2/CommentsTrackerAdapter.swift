import WordPressComments
import WordPressShared

/// Maps `CommentsTrackedEvent` to the app's real analytics events, attaching the
/// site segmentation (blog_id, site_type) that legacy `CommentAnalytics` adds via
/// the blog-associated track overload.
struct CommentsTrackerAdapter: CommentsTracker {
    /// Captured once at construction as a `Sendable` snapshot.
    private let blogProperties: BlogAnalyticsProperties

    init(blogProperties: BlogAnalyticsProperties) {
        self.blogProperties = blogProperties
    }

    func track(_ event: CommentsTrackedEvent) {
        let (analyticsEvent, commentID, postID): (WPAnalyticsEvent, Int64, Int64) =
            switch event {
            case .detailViewed(let commentID, let postID): (.commentViewed, commentID, postID)
            }
        WPAnalytics.track(
            analyticsEvent,
            properties: [
                "context": "sites",
                WPAppAnalyticsKeyPostID: postID,
                WPAppAnalyticsKeyCommentID: commentID
            ],
            blogProperties: blogProperties
        )
    }
}
