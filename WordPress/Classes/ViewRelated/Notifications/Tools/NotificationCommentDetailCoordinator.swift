import Foundation

// This facilitates showing the CommentDetailViewController within the context of Notifications.

class NotificationCommentDetailCoordinator: NSObject {

    // MARK: - Properties

    private var notification: Notification?
    private var comment: Comment?
    private let managedObjectContext = ContextManager.shared.mainContext
    private var viewController: CommentDetailViewController?
    private var blog: Blog?
    private var commentID: NSNumber? {
        notification?.metaCommentID
    }

    // Arrow navigation data source
    private weak var notificationsNavigationDataSource: NotificationsNavigationDataSource?

    // Closure to be executed whenever the notification that's being currently displayed, changes.
    // This happens due to Navigation Events (Next / Previous)
    var onSelectedNoteChange: ((Notification) -> Void)?

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
        configure(with: notification)

        if let comment = loadCommentFromCache(commentID) {
            createViewController(comment: comment) {
                completion(self.viewController)
            }
            return
        }

        fetchComment(commentID, completion: { comment in
            guard let comment = comment else {
                // TODO: show error view
                completion(nil)
                return
            }

            self.createViewController(comment: comment, completion: {
                completion(self.viewController)
            })
        })
    }

}

// MARK: - Private Extension

private extension NotificationCommentDetailCoordinator {

    func configure(with notification: Notification) {
        // Clear previous notification's properties.
        blog = nil
        comment = nil

        self.notification = notification

        if let siteID = notification.metaSiteID {
            blog = Blog.lookup(withID: siteID, in: managedObjectContext)
        }
    }

    func loadCommentFromCache(_ commentID: NSNumber?) -> Comment? {
        guard let commentID = commentID,
              let blog = blog else {
                  DDLogError("Notification Comment: unable to load comment due to missing information.")
                  // TODO: show error view
                  return nil
              }

        return commentService.findComment(withID: commentID, in: blog)
    }

    func fetchComment(_ commentID: NSNumber?, completion: @escaping (Comment?) -> Void) {
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
            completion(nil)
        })
    }

    func fetchParentCommentIfNeeded(completion: @escaping () -> Void) {
        // If the comment has a parent and it is not cached, fetch it so the details header is correct.
        guard let notification = notification,
              let parentID = notification.metaParentID,
              loadCommentFromCache(parentID) == nil else {
                  completion()
                  return
              }

        fetchComment(parentID, completion: { _ in
            completion()
        })
    }

    func createViewController(comment: Comment, completion: @escaping () -> Void) {
        self.comment = comment

        fetchParentCommentIfNeeded(completion: { [weak self] in
            guard let self = self else {
                return
            }

            self.viewController = CommentDetailViewController(comment: comment,
                                                              notification: self.notification,
                                                              notificationNavigationDelegate: self,
                                                              managedObjectContext: self.managedObjectContext)

            self.updateNavigationButtonStates()
            completion()
        })
    }

    func updateViewWith(notification: Notification) {
        trackDetailsOpened(for: notification)
        onSelectedNoteChange?(notification)

        guard notification.kind == .comment else {
            showNotificationDetails(with: notification)
            return
        }

        configure(with: notification)

        fetchParentCommentIfNeeded(completion: { [weak self] in
            self?.refreshViewController()
        })
    }

    func showNotificationDetails(with notification: Notification) {
        let storyboard = UIStoryboard(name: Notifications.storyboardName, bundle: nil)

        guard let viewController = viewController,
        let notificationDetailsViewController = storyboard.instantiateViewController(withIdentifier: Notifications.viewControllerName) as? NotificationDetailsViewController else {
            DDLogError("NotificationCommentDetailCoordinator: missing view controller.")
            return
        }

        notificationDetailsViewController.note = notification
        notificationDetailsViewController.notificationCommentDetailCoordinator = self
        notificationDetailsViewController.dataSource = notificationsNavigationDataSource
        notificationDetailsViewController.onSelectedNoteChange = onSelectedNoteChange

        weak var navigationController = viewController.navigationController

        viewController.dismiss(animated: true, completion: {
            notificationDetailsViewController.navigationItem.largeTitleDisplayMode = .never
            navigationController?.popViewController(animated: false)
            navigationController?.pushViewController(notificationDetailsViewController, animated: false)
        })
    }

    func refreshViewController() {
        if let comment = loadCommentFromCache(commentID) {
            self.comment = comment
            viewController?.refreshView(comment: comment, notification: notification)
            updateNavigationButtonStates()
            return
        }

        fetchComment(commentID, completion: { comment in
            guard let comment = comment else {
                // TODO: show error view
                return
            }

            self.comment = comment
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

    enum Notifications {
        static let storyboardName = "Notifications"
        static let viewControllerName = NotificationDetailsViewController.classNameWithoutNamespaces()
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
