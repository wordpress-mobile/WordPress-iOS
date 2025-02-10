import Foundation

final class CommentCellViewModel: NSObject {
    @objc let comment: Comment
    private let notification: Notification?
    private let coreDataStack = ContextManager.shared

    init(comment: Comment, notification: Notification?) {
        self.comment = comment
        self.notification = notification
    }

    func buttonLikeTapped() {
        guard let siteID else {
            return wpAssertionFailure("context missing")
        }
        if comment.isLiked {
            notification != nil ? WPAppAnalytics.track(.notificationsCommentUnliked, withBlogID: siteID) : CommentAnalytics.trackCommentUnLiked(comment: comment)
        } else {
            notification != nil ? WPAppAnalytics.track(.notificationsCommentLiked, withBlogID: siteID) : CommentAnalytics.trackCommentLiked(comment: comment)
        }

        let service = CommentService(coreDataStack: coreDataStack)
        if !comment.isLiked {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        service.toggleLikeStatus(for: comment, siteID: siteID, success: { [weak self] in
            self?.didToggleLike()
        }, failure: { error in
            Notice(title: Strings.failedToLike, message: error?.localizedDescription).post()
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        })
    }

    private func didToggleLike() {
        guard let notification, let mediator = NotificationSyncMediator() else { return }
        mediator.invalidateCacheForNotification(notification.notificationId) {
            mediator.syncNote(with: notification.notificationId)
        }
    }

    private var siteID: NSNumber? {
        if let siteID = (comment.post as? ReaderPost)?.siteID {
            return siteID
        }
        if let siteID = comment.blog?.dotComID {
            return siteID
        }
        if let siteID = notification?.metaSiteID {
            return siteID
        }
        return nil
    }
}

private enum Strings {
    static let failedToLike = NSLocalizedString("comments.failedToLike", value: "Failed to like comment", comment: "Error title")
}
