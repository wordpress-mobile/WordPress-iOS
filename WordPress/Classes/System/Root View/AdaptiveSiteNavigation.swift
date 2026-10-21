import UIKit
import WordPressData

/// Keeps the site menu and selected content in one adaptive hierarchy.
@MainActor
final class AdaptiveSiteNavigation: SiteMenuViewControllerDelegate {
    let blog: Blog?
    let tab: UITab

    private let menu: SiteMenuViewController?
    private let content: AdaptiveListDetailViewController?
    private var isPushingDestination = false

    var onSiteSelected: ((Blog?) -> Void)?

    init(blog: Blog?) {
        self.blog = blog
        let root: UIViewController
        if let blog {
            let menu = SiteMenuViewController(blog: blog, usesAdaptiveNavigation: true)
            self.menu = menu
            let content = AdaptiveListDetailViewController(list: menu)
            self.content = content
            root = content
        } else {
            menu = nil
            content = nil
            root = UINavigationController(rootViewController: MySiteViewController())
        }
        // UIKit reconciles tabs by identifier. A new site starts with a fresh hierarchy.
        let siteIdentifier = blog?.objectID.uriRepresentation().absoluteString ?? "none"
        tab = UITab(
            title: NSLocalizedString("My Site", comment: "The My Site tab"),
            image: UIImage(systemName: "house"),
            identifier: "site.\(siteIdentifier)"
        ) { _ in root }
        tab.preferredPlacement = .fixed
        tab.accessibilityIdentifier = "tabbar_mysites"
        menu?.navigationItem.backButtonDisplayMode = .minimal
        menu?.delegate = self
        menu?.loadViewIfNeeded()
        if let landing = (root as? UINavigationController)?.viewControllers.first as? MySiteViewController {
            landing.onSiteSelected = { [weak self] in self?.onSiteSelected?($0) }
        }
    }

    func show(_ kind: BlogDetailsRowKind, userInfo: [String: Any]) {
        // Routes from dashboard cards belong to the current detail's Back history.
        isPushingDestination = kind != .home
        defer { isPushingDestination = false }
        menu?.showSubsection(kind, userInfo: userInfo)
    }

    func siteMenuViewController(
        _ siteMenuViewController: SiteMenuViewController,
        showDetailsViewController viewController: UIViewController
    ) {
        if let home = viewController as? MySiteViewController {
            home.navigationItem.backButtonDisplayMode = .minimal
            home.onSiteSelected = { [weak self] in self?.onSiteSelected?($0) }
        }
        if isPushingDestination {
            content?.pushDetail(viewController, animated: true)
        } else {
            content?.showDetail(viewController)
        }
    }
}
