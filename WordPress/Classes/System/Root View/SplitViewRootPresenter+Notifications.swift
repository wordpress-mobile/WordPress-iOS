import Foundation
import UIKit

class NotificationsSplitViewContent: SplitViewDisplayable {
    let supplementary: UINavigationController
    let notificationsViewController: NotificationsViewController
    var secondary: UINavigationController

    init() {
        notificationsViewController = Notifications.instantiateInitialViewController()
        supplementary = UINavigationController(rootViewController: notificationsViewController)
        secondary = UINavigationController()

        notificationsViewController.isSidebarModeEnabled = true
    }

    func displayed(in splitVC: UISplitViewController) {
        // Do nothing
    }
}
