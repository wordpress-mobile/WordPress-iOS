import WordPressData

extension JetpackPostAccessLevel {
    /// Returns the localized display name for the access level
    var localizedDisplayName: String {
        switch self {
        case .everybody: NSLocalizedString(
            "jetpackPostAccessLevel.everybody.title",
            value: "Everyone",
            comment: "Title for post access level that allows everyone to view the post"
        )
        case .subscribers: NSLocalizedString(
            "jetpackPostAccessLevel.subscribers.title",
            value: "Subscribers",
            comment: "Title for post access level that allows only subscribers to view the post"
        )
        case .paidSubscribers: NSLocalizedString(
            "jetpackPostAccessLevel.paidSubscribers.title",
            value: "Paid subscribers",
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
            value: "Only subscribers can view this post",
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
