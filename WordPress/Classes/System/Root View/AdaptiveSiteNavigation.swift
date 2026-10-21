import UIKit
import WordPressData

/// Shares one site navigation stack across all window sizes.
@MainActor
final class AdaptiveSiteNavigation: BlogDetailsPresentationDelegate {
    let landing = MySiteViewController()
    let navigationController: UINavigationController
    let tab: UITab

    // The dashboard replaces the menu's view, but routes still use its screen factories.
    private var menu: BlogDetailsViewController?

    var onSiteSelected: ((Blog?) -> Void)?

    var blog: Blog? { landing.blog }

    init(blog: Blog?) {
        let navigationController = UINavigationController(rootViewController: landing)
        self.navigationController = navigationController
        // UIKit reconciles tabs by identifier. Distinct site identifiers reset navigation when switching sites.
        let siteIdentifier = blog?.objectID.uriRepresentation().absoluteString ?? "none"
        tab = UITab(
            title: NSLocalizedString("My Site", comment: "The My Site tab"),
            image: UIImage(systemName: "house"),
            identifier: "site.\(siteIdentifier)"
        ) { _ in navigationController }
        tab.preferredPlacement = .fixed
        tab.accessibilityIdentifier = "tabbar_mysites"
        navigationController.navigationBar.prefersLargeTitles = true
        landing.navigationItem.backButtonDisplayMode = .minimal
        landing.supportsDashboardInRegularWidth = true
        landing.onSiteSelected = { [weak self] in self?.onSiteSelected?($0) }
        landing.onSiteMenuCreated = { [weak self] in self?.configure(menu: $0) }
        landing.loadViewIfNeeded()
        if let blog { landing.blog = blog }
    }

    private func configure(menu: BlogDetailsViewController) {
        self.menu = menu
        menu.modalPresenter = navigationController
        menu.loadViewIfNeeded()
        menu.presentationDelegate = self
    }

    func show(_ kind: BlogDetailsRowKind, userInfo: [String: Any]) {
        if kind == .home {
            navigationController.popToRootViewController(animated: true)
        } else {
            menu?.showDetailView(for: kind, userInfo: userInfo)
        }
    }

    func presentBlogDetailsViewController(_ viewController: UIViewController) {
        navigationController.pushViewController(viewController, animated: true)
    }
}
