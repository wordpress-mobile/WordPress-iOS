import Foundation
import UIKit

class SiteSplitViewContent: SiteMenuViewControllerDelegate, SplitViewDisplayable {
    let siteMenuVC: SiteMenuViewController
    let supplementary: UINavigationController
    var secondary: UINavigationController

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
        RecentSitesService().touch(blog: blog)

        _ = siteMenuVC.view
    }

    func siteMenuViewController(_ siteMenuViewController: SiteMenuViewController, showDetailsViewController viewController: UIViewController) {
        guard siteMenuVC === siteMenuViewController, let splitVC = siteMenuViewController.splitViewController else { return }

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
