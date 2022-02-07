import Foundation

// This facilitates showing the CommentDetailViewController within the context of Notifications.

class NotificationCommentDetailCoordinator: NSObject {

    // MARK: - Properties

    private let notification: Notification
    private var comment: Comment?
    private let managedObjectContext = ContextManager.shared.mainContext
    private var viewController: CommentDetailViewController?
    private var commentID: NSNumber?
    private var blog: Blog?

    private lazy var commentService: CommentService = {
        return .init(managedObjectContext: managedObjectContext)
    }()

    // MARK: - Init

    init(notification: Notification) {
        self.notification = notification
        commentID = notification.metaCommentID

        if let siteID = notification.metaSiteID {
            blog = Blog.lookup(withID: siteID, in: managedObjectContext)
        }

        super.init()
    }

    // MARK: - Public Methods

    func createViewController(completion: @escaping (CommentDetailViewController?) -> Void) {
        if let comment = loadCommentFromCache() {
            createViewController(comment: comment)
            completion(viewController)
            return
        }

        fetchComment(completion: { comment in
            guard let comment = comment else {
                // TODO: show error view
                completion(nil)
                return
            }

            self.createViewController(comment: comment)
            completion(self.viewController)
        })
    }

}

// MARK: - Private Extension

private extension NotificationCommentDetailCoordinator {

    func loadCommentFromCache() -> Comment? {
        guard let commentID = commentID,
              let blog = blog else {
                  DDLogError("Notification Comment: unable to load comment due to missing information.")
                  // TODO: show error view
                  return nil
              }

        return commentService.findComment(withID: commentID, in: blog)
    }

    func fetchComment(completion: @escaping (Comment?) -> Void) {
        guard let commentID = commentID,
              let blog = blog else {
                  DDLogError("Notification Comment: unable to fetch comment due to missing information.")
                  // TODO: show error view
                  completion(nil)
                  return
              }

        // TODO: show loading view

        commentService.loadComment(withID: commentID, for: blog, success: { comment in
            completion(comment)
        }, failure: { error in
            // TODO: show error view
        })
    }

    func createViewController(comment: Comment) {
        self.comment = comment
        viewController = CommentDetailViewController(comment: comment,
                                                     notification: notification,
                                                     managedObjectContext: managedObjectContext)
    }

}
