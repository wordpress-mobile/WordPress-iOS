import Foundation

/// Utility extension to track specific data for passing to on to WPAppAnalytics.
public extension WPAppAnalytics {

    enum FollowAction: String {
        case followed
        case unfollowed
    }

    /// Get a dictionary of tracking properties for a Media object with the media selection method.
    ///
    /// - Parameters:
    ///     - post: The Post object.
    ///     - followAction: Followed or unfollowed action.
    /// - Returns: Dictionary
    ///
    class func properties(for post: ReaderPost, followAction: FollowAction) -> [String: Any] {
        var properties = [String: Any]()
        properties[WPAppAnalyticsKeyFollowAction] = followAction.rawValue
        properties[WPAppAnalyticsKeyBlogID] = post.siteID
        return properties
    }
}
