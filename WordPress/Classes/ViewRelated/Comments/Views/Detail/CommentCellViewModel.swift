import UIKit
import Combine
import WordPressShared

final class CommentCellViewModel: NSObject {
    @objc let comment: Comment

    private let notification: Notification?
    private let coreDataStack = ContextManager.shared

    @Published private(set) var content: String?
    @Published private(set) var avatar: Avatar?
    @Published private(set) var state: State

    init(comment: Comment, notification: Notification? = nil) {
        self.comment = comment
        self.notification = notification

        self.content = comment.content
        self.state = State(comment: comment)
        self.avatar = Avatar(comment: comment)

        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(objectDidChange), name: .NSManagedObjectContextObjectsDidChange, object: comment.managedObjectContext)
    }

    // MARK: State

    struct State: Hashable {
        var title: String
        var dateCreated: Date?
        var isLiked: Bool
        var likeCount: Int
        var isLikeEnabled: Bool
        var isReplyEnabled: Bool

        init(comment: Comment) {
            self.title = comment.authorForDisplay()
            self.dateCreated = comment.dateCreated
            self.isLiked = comment.isLiked
            self.likeCount = Int(comment.likeCount)
            self.isLikeEnabled = comment.canLike()
            self.isReplyEnabled = comment.canReply()
        }
    }

    enum Avatar: Hashable {
        case url(URL)
        case email(String)

        init?(comment: Comment) {
            if let imageURL = comment.avatarURLForDisplay() {
                self = .url(imageURL)
            } else {
                let email = comment.gravatarEmailForDisplay()
                guard !email.isEmpty else {
                    return nil
                }
                self = .email(email)
            }
        }
    }

    /// This method emits changes only when something actually changes in the object.
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

        let avatar = Avatar(comment: comment)
        if avatar != self.avatar {
            self.avatar = avatar
        }

        if comment.content != self.content {
            self.content = comment.content
        }
    }

    // MARK: Actions

    func buttonLikeTapped() {
        guard let siteID else {
            return wpAssertionFailure("context missing")
        }
        if comment.isLiked {
            notification != nil ? WPAppAnalytics.track(.notificationsCommentUnliked, blogID: siteID) : CommentAnalytics.trackCommentUnLiked(comment: comment)
        } else {
            notification != nil ? WPAppAnalytics.track(.notificationsCommentLiked, blogID: siteID) : CommentAnalytics.trackCommentLiked(comment: comment)
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
