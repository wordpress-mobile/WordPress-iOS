import Foundation

// This facilitates showing the CommentDetailViewController within the context of Notifications.

class NotificationCommentDetailCoordinator: NSObject {

    // MARK: - Properties

    private var notification: Notification?
    private var comment: Comment?
    private let managedObjectContext = ContextManager.shared.mainContext
    private var viewController: CommentDetailViewController?
    private var commentID: NSNumber?
    private var blog: Blog?

    // Arrow navigation data source
    private weak var notificationsNavigationDataSource: NotificationsNavigationDataSource?

    private lazy var commentService: CommentService = {
        return .init(managedObjectContext: managedObjectContext)
    }()

    // MARK: - Init

    init(notificationsNavigationDataSource: NotificationsNavigationDataSource? = nil) {
        self.notificationsNavigationDataSource = notificationsNavigationDataSource
        super.init()
    }

    // MARK: - Public Methods

    func createViewController(with notification: Notification,
                              completion: @escaping (CommentDetailViewController?) -> Void) {
        configureWith(notification: notification)

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

    func configureWith(notification: Notification) {
        self.notification = notification
        commentID = notification.metaCommentID

        if let siteID = notification.metaSiteID {
            blog = Blog.lookup(withID: siteID, in: managedObjectContext)
        }
    }

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
                                                     notificationNavigationDelegate: self,
                                                     managedObjectContext: managedObjectContext)

        updateNavigationButtonStates()
    }

    func updateViewWith(notification: Notification) {
        if notification.kind == .comment {
            trackDetailsOpened(for: notification)
            configureWith(notification: notification)
            refreshViewController()
        } else {
            // TODO: handle other notification type
        }
    }

    func refreshViewController() {
        if let comment = loadCommentFromCache() {
            viewController?.refreshView(comment: comment, notification: notification)
            updateNavigationButtonStates()
            return
        }

        fetchComment(completion: { comment in
            guard let comment = comment else {
                // TODO: show error view
                return
            }

            self.viewController?.refreshView(comment: comment, notification: self.notification)
            self.updateNavigationButtonStates()
        })
    }

    func updateNavigationButtonStates() {
        viewController?.previousButtonEnabled = hasPreviousNotification
        viewController?.nextButtonEnabled = hasNextNotification
    }

    var hasPreviousNotification: Bool {
        guard let notification = notification else {
            return false
        }

        return notificationsNavigationDataSource?.notification(preceding: notification) != nil
    }

    var hasNextNotification: Bool {
        guard let notification = notification else {
            return false
        }
        return notificationsNavigationDataSource?.notification(succeeding: notification) != nil
    }


    func trackDetailsOpened(for notification: Notification) {
        let properties = ["notification_type": notification.type ?? "unknown"]
        WPAnalytics.track(.openedNotificationDetails, withProperties: properties)
    }

}

// MARK: - CommentDetailsNotificationNavigationDelegate

extension NotificationCommentDetailCoordinator: CommentDetailsNotificationNavigationDelegate {

    func previousNotificationTapped(current: Notification?) {
        guard let current = current,
              let previousNotification = notificationsNavigationDataSource?.notification(preceding: current) else {
                  return
              }

        WPAnalytics.track(.notificationsPreviousTapped)
        updateViewWith(notification: previousNotification)
    }

    func nextNotificationTapped(current: Notification?) {
        guard let current = current,
              let nextNotification = notificationsNavigationDataSource?.notification(succeeding: current) else {
                  return
              }

        WPAnalytics.track(.notificationsNextTapped)
        updateViewWith(notification: nextNotification)
    }

}
