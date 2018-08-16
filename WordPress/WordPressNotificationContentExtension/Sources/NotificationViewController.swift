import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?
    
    func didReceive(_ notification: UNNotification) {
        self.label?.text = notification.request.content.body
    }
}
