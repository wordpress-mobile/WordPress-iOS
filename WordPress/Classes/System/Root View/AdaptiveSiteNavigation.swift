import UIKit
import WordPressData

/// Keeps the site menu and selected content in one adaptive hierarchy.
@MainActor
final class AdaptiveSiteNavigation: NSObject, SiteMenuViewControllerDelegate {
    let blog: Blog?
    let tab: UITab

    private let menu: SiteMenuViewController?
    private let content: AdaptiveListDetailViewController?
    private var isPushingDestination = false
    private var home: MySiteViewController?

    var onSiteSelected: ((Blog?) -> Void)?

    init(blog: Blog?) {
        self.blog = blog
        let root: UIViewController
        if let blog {
            let menu = SiteMenuViewController(blog: blog, usesAdaptiveNavigation: true)
            self.menu = menu
            // TODO: Hiding tabs here leaves a stale top inset after expansion on iPadOS 27.
            let content = AdaptiveListDetailViewController(list: menu, usesDetailForCompactWidth: true)
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
        super.init()
        tab.preferredPlacement = .fixed
        tab.accessibilityIdentifier = "tabbar_mysites"
        menu?.navigationItem.backButtonDisplayMode = .minimal
        menu?.delegate = self
        content?.onDetailDidShow = { [weak self] viewController in
            guard let self, viewController === self.home else { return }
            self.menu?.selectSubsection(.home)
        }
        content?.onListVisibilityChanged = { [weak self] isVisible in
            self?.home?.isSiteMenuVisible = isVisible
        }
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
        guard let content, let blog else { return }
        if home == nil {
            let home =
                (viewController as? MySiteViewController)
                ?? MySiteViewController.make(forBlog: blog, supportsDashboardInRegularWidth: true)
            home.navigationItem.backButtonDisplayMode = .minimal
            home.onSiteSelected = { [weak self] in self?.onSiteSelected?($0) }
            home.isSiteMenuVisible = content.isListVisible
            self.home = home
            content.showDetail(home)
        }
        if viewController is MySiteViewController, let home {
            content.showDetail(home)
        } else if isPushingDestination {
            content.pushDetail(viewController, animated: true)
        } else {
            content.showDetail(viewController, keeping: home)
        }
    }
}
