import UIKit
import UserNotifications
import UserNotificationsUI

@objc(NotificationViewController)
class NotificationViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.orange

        let currentRect = view.frame
        let viewRect = CGRect(
            x: currentRect.origin.x,
            y: currentRect.origin.y,
            width: currentRect.width,
            height: 44)
        view.frame = viewRect
    }
}

extension NotificationViewController: UNNotificationContentExtension {
    func didReceive(_ notification: UNNotification) {
        debugPrint(#function)
    }
}
