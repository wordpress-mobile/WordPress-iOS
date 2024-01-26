import Foundation

// This facilitates showing the CommentDetailViewController within the context of Notifications.

protocol CommentDetailsNotificationDelegate: AnyObject {
    func previousNotificationTapped(current: Notification?)
    func nextNotificationTapped(current: Notification?)
    func commentWasModerated(for notification: Notification?)
}

class NotificationCommentDetailCoordinator: NSObject {

    // MARK: - Properties

    private var viewController: NotificationCommentDetailViewController?
    private let managedObjectContext = ContextManager.shared.mainContext

    private var notification: Notification? {
        didSet {
            markNotificationReadIfNeeded()
        }
    }

    // Arrow navigation data source
    private weak var notificationsNavigationDataSource: NotificationsNavigationDataSource?

    // Closure to be executed whenever the notification that's being currently displayed, changes.
    // This happens due to Navigation Events (Next / Previous)
    var onSelectedNoteChange: ((Notification) -> Void)?

    // Keep track of Notifications that have moderated Comments so they can be updated
    // the next time the Notifications list is displayed.
    var notificationsCommentModerated: [Notification] = []

    // MARK: - Init

    init(notificationsNavigationDataSource: NotificationsNavigationDataSource? = nil) {
        self.notificationsNavigationDataSource = notificationsNavigationDataSource
        super.init()
    }

    // MARK: - Public Methods

    func createViewController(with notification: Notification) -> NotificationCommentDetailViewController? {
        self.notification = notification
        viewController = NotificationCommentDetailViewController(notification: notification, notificationDelegate: self)
        updateNavigationButtonStates()
        return viewController
    }

}

// MARK: - Private Extension

private extension NotificationCommentDetailCoordinator {

    func markNotificationReadIfNeeded() {
        guard let notification = notification, !notification.read else {
            return
        }

        NotificationSyncMediator()?.markAsRead(notification)
    }

    func updateViewWith(notification: Notification) {
        trackDetailsOpened(for: notification)
        onSelectedNoteChange?(notification)

        guard notification.kind == .comment else {
            showNotificationDetails(with: notification)
            return
        }

        refreshViewControllerWith(notification)
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

    func refreshViewControllerWith(_ notification: Notification) {
        self.notification = notification
        viewController?.refreshViewController(notification: notification)
        updateNavigationButtonStates()
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

// MARK: - CommentDetailsNotificationDelegate

extension NotificationCommentDetailCoordinator: CommentDetailsNotificationDelegate {

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

    func commentWasModerated(for notification: Notification?) {
        guard let notification = notification,
              !notificationsCommentModerated.contains(notification) else {
                  return
              }

        notificationsCommentModerated.append(notification)
    }

}
