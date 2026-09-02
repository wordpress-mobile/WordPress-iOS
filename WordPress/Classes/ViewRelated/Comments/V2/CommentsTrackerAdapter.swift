import WordPressComments
import WordPressShared

/// Maps `CommentsTrackedEvent` to the app's real analytics events, attaching the
/// site segmentation (blog_id, site_type) that legacy `CommentAnalytics` adds via
/// the blog-associated track overload.
struct CommentsTrackerAdapter: CommentsTracker {
    /// Captured once at construction as a `Sendable` snapshot: `track(_:)`
    /// is a non-isolated protocol requirement.
    private let blogProperties: BlogAnalyticsProperties

    init(blogProperties: BlogAnalyticsProperties) {
        self.blogProperties = blogProperties
    }

    func track(_ event: CommentsTrackedEvent) {
        let (analyticsEvent, commentID, postID): (WPAnalyticsEvent, Int64, Int64) =
            switch event {
            case .detailViewed(let c, let p): (.commentViewed, c, p)
            case .approved(let c, let p): (.commentApproved, c, p)
            case .unapproved(let c, let p): (.commentUnApproved, c, p)
            case .spammed(let c, let p): (.commentSpammed, c, p)
            case .trashed(let c, let p): (.commentTrashed, c, p)
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
