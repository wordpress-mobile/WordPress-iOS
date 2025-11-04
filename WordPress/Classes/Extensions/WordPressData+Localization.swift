import WordPressData

extension JetpackPostAccessLevel {
    /// Returns the localized display name for the access level
    var localizedTitle: String {
        switch self {
        case .everybody: NSLocalizedString(
            "jetpackPostAccessLevel.everybody.title",
            value: "Everyone",
            comment: "Title for post access level that allows everyone to view the post"
        )
        case .subscribers: NSLocalizedString(
            "jetpackPostAccessLevel.subscribers.title",
            value: "All Subscribers",
            comment: "Title for post access level that allows only subscribers to view the post"
        )
        case .paidSubscribers: NSLocalizedString(
            "jetpackPostAccessLevel.paidSubscribers.title",
            value: "Paid Subscribers",
            comment: "Title for post access level that allows only paid subscribers to view the post"
        )
        }
    }

    /// Returns the localized description for the access level
    var localizedDescription: String {
        switch self {
        case .everybody: NSLocalizedString(
            "jetpackPostAccessLevel.everybody.description",
            value: "Anyone can view this post",
            comment: "Description for post access level that allows everyone to view the post"
        )
        case .subscribers: NSLocalizedString(
            "jetpackPostAccessLevel.subscribers.description",
            value: "The post is visible to all subscribers, including free ones",
            comment: "Description for post access level that allows only subscribers to view the post"
        )
        case .paidSubscribers: NSLocalizedString(
            "jetpackPostAccessLevel.paidSubscribers.description",
            value: "Only paid subscribers can view this post",
            comment: "Description for post access level that allows only paid subscribers to view the post"
        )
        }
    }
}
