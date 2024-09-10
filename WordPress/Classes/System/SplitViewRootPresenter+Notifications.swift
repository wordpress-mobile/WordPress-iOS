import Foundation
import UIKit

class NotificationsSplitViewContent: SplitViewDisplayable {
    let navigationController: UINavigationController
    let notificationsViewController: NotificationsViewController
    var content: UINavigationController

    var selection: SidebarSelection {
        .notifications
    }

    var supplimentary: UINavigationController {
        navigationController
    }

    var secondary: UINavigationController? {
        get { content }
        set {
            if let newValue {
                content = newValue
            }
        }
    }

    init() {
        notificationsViewController = UIStoryboard(name: "Notifications", bundle: nil).instantiateInitialViewController() as! NotificationsViewController
        navigationController = UINavigationController(rootViewController: notificationsViewController)
        content = UINavigationController()

        notificationsViewController.isSidebarModeEnabled = true
    }

    func displayed(in splitVC: UISplitViewController) {
        // Do nothing
    }

    func refresh(with splitVC: UISplitViewController) {
        guard isDisplaying(in: splitVC) else { return }
        guard let currentContent = splitVC.viewController(for: .secondary) as? UINavigationController else { return }

        self.content = currentContent
    }
}
