import Foundation
import UIKit

class SiteSplitViewContent: SiteMenuViewControllerDelegate, SplitViewDisplayable {
    let siteMenu: SiteMenuViewController
    let supplementary: UINavigationController
    var secondary: UINavigationController

    var blog: Blog {
        siteMenu.blog
    }

    init(blog: Blog) {
        siteMenu = SiteMenuViewController(blog: blog)
        supplementary = UINavigationController(rootViewController: siteMenu)
        secondary = UINavigationController()
        siteMenu.delegate = self
    }

    func displayed(in splitVC: UISplitViewController) {
        RecentSitesService().touch(blog: blog)

        // TODO: (wpsidebar) Refactor this (initial .secondary vc managed based on the VC presentation)
        _ = siteMenu.view
    }

    func siteMenuViewController(_ siteMenuViewController: SiteMenuViewController, showDetailsViewController viewController: UIViewController) {
        guard siteMenu === siteMenuViewController, let splitVC = siteMenuViewController.splitViewController else { return }

        if viewController is UINavigationController ||
            viewController is UISplitViewController {
            splitVC.setViewController(viewController, for: .secondary)
        } else {
            // Reset previous navigation or split stack
            let navigationVC = UINavigationController(rootViewController: viewController)
            splitVC.setViewController(navigationVC, for: .secondary)
        }
    }
}
