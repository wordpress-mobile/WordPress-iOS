
struct NotificationContentRouter {
    private let coordinator: ContentCoordinator
    private let notification: Notification
    private let expirationFiveMinutes = TimeInterval(60 * 5)

    init(activity: Notification, coordinator: ContentCoordinator) {
        self.coordinator = coordinator
        self.notification = activity
    }

    func routeTo(_ url: URL) throws {
        guard let range = getRange(with: url) else {
            return
        }
        try displayContent(of: range, with: url)
    }

    private func displayContent(of range: FormattableContentRange, with url: URL) throws {
        guard let range = range as? NotificationContentRange else {
            throw DefaultContentCoordinator.DisplayError.missingParameter
        }

        switch range.kind {
        case .site:
            try coordinator.displayStreamWithSiteID(range.siteID)
        case .post:
            try coordinator.displayReaderWithPostId(range.postID, siteID: range.siteID)
        case .comment:
            try coordinator.displayCommentsWithPostId(range.postID, siteID: range.siteID)
        case .stats:
            try coordinator.displayStatsWithSiteID(range.siteID)
        case .follow:
            try coordinator.displayFollowersWithSiteID(range.siteID, expirationTime: expirationFiveMinutes)
        case .user:
            try coordinator.displayStreamWithSiteID(range.siteID)
        default:
            throw DefaultContentCoordinator.DisplayError.unsupportedType
        }
    }

    private func getRange(with url: URL) -> FormattableContentRange? {
        return notification.contentRange(with: url)
    }
}
