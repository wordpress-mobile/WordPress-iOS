
struct NotificationContentRouter {
    private let coordinator: ContentCoordinator
    private let notification: Notification
    private let expirationFiveMinutes = TimeInterval(60 * 5)

    init(activity: Notification, coordinator: ContentCoordinator) {
        self.coordinator = coordinator
        self.notification = activity
    }

    func routeTo(_ url: URL) {
        guard let range = getRange(with: url) else {
            return
        }
        do {
            try displayContent(of: range, with: url)
        } catch {
            coordinator.displayWebViewWithURL(url)
        }
    }

    /// Route to the controller that best represents the notification source.
    ///
    /// - Throws: throws if the notification doesn't have a resource URL
    ///
    func routeToNotificationSource() throws {
        guard let fallbackURL = notification.resourceURL else {
            throw DefaultContentCoordinator.DisplayError.missingParameter
        }
        do {
            try displayNotificationSource()
        } catch {
            coordinator.displayWebViewWithURL(fallbackURL)
        }
    }

    func routeTo(_ image: UIImage) {
        coordinator.displayFullscreenImage(image)
    }

    private func displayNotificationSource() throws {
        switch notification.kind {
        case .Follow:
            try coordinator.displayStreamWithSiteID(notification.metaSiteID)
        case .Like:
            fallthrough
        case .Matcher:
            fallthrough
        case .NewPost:
            fallthrough
        case .Post:
            try coordinator.displayReaderWithPostId(notification.metaPostID, siteID: notification.metaSiteID)
        case .Comment:
            fallthrough
        case .CommentLike:
            try coordinator.displayCommentsWithPostId(notification.metaPostID, siteID: notification.metaSiteID)
        default:
            throw DefaultContentCoordinator.DisplayError.unsupportedType
        }
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
