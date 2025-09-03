import Foundation
import UIKit
import WordPressData

class SiteSplitViewContent: SiteMenuViewControllerDelegate, SplitViewDisplayable {
    let siteMenuVC: SiteMenuViewController
    let supplementary: UINavigationController
    var secondary: UINavigationController

    private weak var splitViewController: UISplitViewController?

    var blog: Blog {
        siteMenuVC.blog
    }

    init(blog: Blog) {
        siteMenuVC = SiteMenuViewController(blog: blog)
        supplementary = UINavigationController(rootViewController: siteMenuVC)
        supplementary.navigationBar.accessibilityIdentifier = "site_menu_navbar"

        secondary = UINavigationController()
        siteMenuVC.delegate = self
    }

    func displayed(in splitVC: UISplitViewController) {
        splitViewController = splitVC

        RecentSitesService().touch(blog: blog)

        _ = siteMenuVC.view
    }

    func siteMenuViewController(_ siteMenuViewController: SiteMenuViewController, showDetailsViewController viewController: UIViewController) {
        // There is an issue on iOS 26 where the 'Home' tab of 'My Site' is selected, but the view controller is not displayed.
        //
        // The root cause is that during the app launch process, the `siteMenuVC.splitViewController` is nil (a.k.a. the `splitVC` variable
        // in the guard statement below), even though `siteMenuVC` is set as the supplementary view controller.
        //
        // The workaround here is keeping the `UISplitViewController` reference and using it as the backup option.
        guard siteMenuVC === siteMenuViewController, let splitVC = siteMenuViewController.splitViewController ?? splitViewController else { return }

        if viewController is UINavigationController ||
            viewController is UISplitViewController {
            splitVC.setViewController(viewController, for: .secondary)
        } else {
            // Reset previous navigation or split stack
            let navigationVC = UINavigationController(rootViewController: viewController)
            splitVC.setViewController(navigationVC, for: .secondary)
        }
    }

    func showSubsection(_ subsection: BlogDetailsSubsection, userInfo: [AnyHashable: Any]) {
        siteMenuVC.showSubsection(subsection, userInfo: userInfo)
    }
}
