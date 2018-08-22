import UIKit
import UserNotifications
import UserNotificationsUI

// MARK: - NotificationViewController

/// Responsible for enhancing the visual appearance of designated push notifications.
@objc(NotificationViewController)
class NotificationViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.groupTableViewBackground
    }
}

// MARK: - UNNotificationContentExtension

extension NotificationViewController: UNNotificationContentExtension {
    func didReceive(_ notification: UNNotification) {
        let notificationContent = notification.request.content
        let viewModel = RichNotificationViewModel(notificationContent: notificationContent)

        debugPrint("Gravatar: \(String(describing: viewModel.gravatarURLString))")
        debugPrint("Noticon: \(String(describing: viewModel.noticon))")
        debugPrint("Subject: \(String(describing: viewModel.attributedSubject))")
        debugPrint("Body: \(String(describing: viewModel.attributedBody))")
    }
}
