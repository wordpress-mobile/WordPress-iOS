import Foundation
import Combine

final class CommentCellViewModel: NSObject {
    @objc let comment: Comment

    private let notification: Notification?
    private let coreDataStack = ContextManager.shared

    @Published private(set) var state: State

    init(comment: Comment, notification: Notification? = nil) {
        self.comment = comment
        self.notification = notification
        self.state = State(comment: comment)
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(objectDidChange), name: .NSManagedObjectContextObjectsDidChange, object: comment.managedObjectContext)
    }

    // MARK: State

    struct State: Hashable {
        var isLiked: Bool
        var likeCount: Int

        init(comment: Comment) {
            self.isLiked = comment.isLiked
            self.likeCount = Int(comment.likeCount)
        }
    }

    @objc private func objectDidChange(_ notification: Foundation.Notification) {
        wpAssert(Thread.isMainThread)

        let updated = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>
        let refreshed = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject>

        guard updated?.contains(comment) ?? refreshed?.contains(comment) ?? false else {
            return
        }

        let state = State(comment: comment)
        if state != self.state {
            self.state = state
        }
    }

    // MARK: Actions

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
