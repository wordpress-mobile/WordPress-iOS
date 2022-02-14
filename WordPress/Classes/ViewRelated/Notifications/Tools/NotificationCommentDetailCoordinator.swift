import Foundation

// This facilitates showing the CommentDetailViewController within the context of Notifications.

class NotificationCommentDetailCoordinator: NSObject {

    // MARK: - Properties

    private let notification: Notification
    private var comment: Comment?
    private let managedObjectContext = ContextManager.shared.mainContext
    private(set) var viewController: CommentDetailViewController?

    private lazy var commentService: CommentService = {
        return .init(managedObjectContext: managedObjectContext)
    }()

    // MARK: - Init

    init(notification: Notification) {
        self.notification = notification
        super.init()
        loadCommentFromCache()
    }

}

// MARK: - Private Extension

private extension NotificationCommentDetailCoordinator {

    func loadCommentFromCache() {
        guard let siteID = notification.metaSiteID,
              let commentID = notification.metaCommentID,
              let blog = Blog.lookup(withID: siteID, in: managedObjectContext),
              let comment = commentService.findComment(withID: commentID, in: blog) else {
                  DDLogError("Notification Comment: failed loading comment from cache.")
                  return
              }

        self.comment = comment
        viewController = CommentDetailViewController(comment: comment,
                                                     notification: notification,
                                                     managedObjectContext: managedObjectContext)
    }

}
