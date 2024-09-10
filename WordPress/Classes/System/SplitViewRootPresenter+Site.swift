import Foundation
import UIKit

class SiteSplitViewContent: SiteMenuViewControllerDelegate, SplitViewDisplayable {
    let siteMenu: SiteMenuViewController
    let siteMenuNavigationController: UINavigationController
    var content: UINavigationController

    var blog: Blog {
        siteMenu.blog
    }

    var selection: SidebarSelection {
        .blog(TaggedManagedObjectID(blog))
    }

    var supplimentary: UINavigationController {
        siteMenuNavigationController
    }

    var secondary: UINavigationController? {
        get { content }
        set {
            if let newValue {
                content = newValue
            }
        }
    }

    init(blog: Blog) {
        siteMenu = SiteMenuViewController(blog: blog)
        siteMenuNavigationController = UINavigationController(rootViewController: siteMenu)
        content = UINavigationController()
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
