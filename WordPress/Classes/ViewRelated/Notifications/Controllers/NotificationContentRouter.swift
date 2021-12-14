
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
            coordinator.displayWebViewWithURL(url, source: "notifications")
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
            coordinator.displayWebViewWithURL(fallbackURL, source: "notifications")
        }
    }

    func routeTo(_ image: UIImage) {
        coordinator.displayFullscreenImage(image)
    }

    private func displayNotificationSource() throws {
        switch notification.kind {
        case .follow:
            try coordinator.displayStreamWithSiteID(notification.metaSiteID)
        case .like:
            fallthrough
        case .matcher:
            fallthrough
        case .newPost:
            fallthrough
        case .post:
            try coordinator.displayReaderWithPostId(notification.metaPostID, siteID: notification.metaSiteID)
        case .comment:
            // Focus on the primary comment, and default to the reply ID if its set
            let commentID = notification.metaCommentID ?? notification.metaReplyID
            try coordinator.displayCommentsWithPostId(notification.metaPostID,
                                                      siteID: notification.metaSiteID,
                                                      commentID: commentID,
                                                      source: .commentNotification)
        case .commentLike:
            // Focus on the primary comment, and default to the reply ID if its set
            let commentID = notification.metaCommentID ?? notification.metaReplyID
            try coordinator.displayCommentsWithPostId(notification.metaPostID,
                                                      siteID: notification.metaSiteID,
                                                      commentID: commentID,
                                                      source: .commentLikeNotification)
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
            // Focus on the comment reply if it's set over the primary comment ID
            let commentID = notification.metaReplyID ?? notification.metaCommentID
            try coordinator.displayCommentsWithPostId(range.postID,
                                                      siteID: range.siteID,
                                                      commentID: commentID,
                                                      source: .commentNotification)
        case .stats:
            /// Backup notifications are configured as "stat" notifications
            /// For now this is just a workaround to fix the routing
            if url.absoluteString.matches(regex: "\\/backup\\/").count > 0 {
                try coordinator.displayBackupWithSiteID(range.siteID)
            } else {
                try coordinator.displayStatsWithSiteID(range.siteID, url: url)
            }
        case .follow:
            try coordinator.displayFollowersWithSiteID(range.siteID, expirationTime: expirationFiveMinutes)
        case .user:
            try coordinator.displayStreamWithSiteID(range.siteID)
        case .scan:
            try coordinator.displayScanWithSiteID(range.siteID)

        default:
            throw DefaultContentCoordinator.DisplayError.unsupportedType
        }
    }

    private func getRange(with url: URL) -> FormattableContentRange? {
        return notification.contentRange(with: url)
    }
}
