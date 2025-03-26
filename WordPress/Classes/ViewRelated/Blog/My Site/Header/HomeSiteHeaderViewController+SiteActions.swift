import UIKit
import SwiftUI
import WordPressShared

extension HomeSiteHeaderViewController {

    func makeSiteActionsMenu() -> UIMenu? {
        UIMenu(options: .displayInline, children: [
            UIDeferredMenuElement.uncached { [weak self] in
                $0(self?.makeSections() ?? [])
            }
        ])
    }

    private func makeSections() -> [UIMenu] {
        let sections = [
            makePrimarySection(),
            makeSecondarySection(),
            makeTertiarySection()
        ]
        return sections.compactMap { $0 }
    }

    private func makePrimarySection() -> UIMenu {
        let menuItems = [
            MenuItem.visitSite { [weak self] in self?.visitSiteTapped() },
            MenuItem.shareSite { [weak self] in self?.buttonShareSiteTapped() },
        ]
        return UIMenu(options: .displayInline, children: menuItems.map { $0.toAction })
    }

    private func makeSecondarySection() -> UIMenu? {
        guard blog.isAdmin else {
            return nil
        }

        var menuItems: [UIMenuElement] = [
            MenuItem.siteTitle({ [weak self] in self?.siteTitleTapped() }).toAction
        ]
        if siteIconShouldAllowDroppedImages() {
            menuItems.append(
                UIMenu(title: Strings.siteIcon, image: UIImage(systemName: "photo.circle"), children: [
                    makeSiteIconMenu() ?? UIMenu()
                ])
            )
        }
        return UIMenu(options: .displayInline, children: menuItems)
    }

    private func makeTertiarySection() -> UIMenu {
        UIMenu(options: .displayInline, children: [
            MenuItem.personalizeHome({ [weak self] in self?.personalizeHomeTapped() }).toAction
        ])
    }

    // MARK: - Actions

    func buttonShareSiteTapped() {
        guard let urlString = blog.homeURL as String?,
              let url = URL(string: urlString) else {
            assertionFailure("Site has no URL")
            return
        }
        let viewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = viewController.popoverPresentationController {
            popover.sourceView = blogDetailHeaderView.titleView.siteSwitcherButton
        }
        present(viewController, animated: true, completion: nil)
        WPAnalytics.trackEvent(.mySiteHeaderShareSiteTapped)
    }

    // MARK: - Add site

    func addSiteTapped(siteType: AddSiteMenuViewModel.Selection) {
        WPAnalytics.trackEvent(.mySiteHeaderAddSiteTapped, properties: ["site_type": siteType.rawValue])
        AddSiteController(viewController: presentedViewController ?? self, source: "my_site")
            .showSiteCreationScreen(selection: siteType)
    }

    // MARK: - Personalize home

    private func personalizeHomeTapped() {
        guard let siteID = blog.dotComID?.intValue else {
            return DDLogError("Failed to show dashboard personalization screen: siteID is missing")
        }

        let viewController = UIHostingController(rootView: NavigationView {
            BlogDashboardPersonalizationView(viewModel: .init(blog: self.blog, service: .init(siteID: siteID)))
        }.navigationViewStyle(.stack)) // .stack is required for iPad
        viewController.modalPresentationStyle = .formSheet
        present(viewController, animated: true)

        WPAnalytics.trackEvent(.mySiteHeaderPersonalizeHomeTapped)
    }

    // MARK: - Helpers

    private func defaultAccount() -> WPAccount? {
        try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
    }
}

private enum MenuItem {
    case visitSite(_ handler: () -> Void)
    case shareSite(_ handler: () -> Void)
    case siteTitle(_ handler: () -> Void)
    case personalizeHome(_ handler: () -> Void)

    var title: String {
        switch self {
        case .visitSite: return Strings.visitSite
        case .shareSite: return SharedStrings.Button.share
        case .siteTitle: return Strings.siteTitle
        case .personalizeHome: return Strings.personalizeHome
        }
    }

    var icon: UIImage? {
        switch self {
        case .visitSite: return UIImage(systemName: "safari")
        case .shareSite: return UIImage(systemName: "square.and.arrow.up")
        case .siteTitle: return UIImage(systemName: "character")
        case .personalizeHome: return UIImage(systemName: "slider.horizontal.3")
        }
    }

    var toAction: UIAction {
        switch self {
        case .visitSite(let handler),
             .shareSite(let handler),
             .siteTitle(let handler),
             .personalizeHome(let handler):
            return UIAction(title: title, image: icon) { _ in handler() }
        }
    }
}

private enum Strings {
    static let visitSite = NSLocalizedString("mySite.siteActions.visitSite", value: "Visit site", comment: "Menu title for the visit site option")
    static let siteTitle = NSLocalizedString("mySite.siteActions.siteTitle", value: "Change site title", comment: "Menu title for the change site title option")
    static let siteIcon = NSLocalizedString("mySite.siteActions.siteIcon", value: "Change site icon", comment: "Menu title for the change site icon option")
    static let personalizeHome = NSLocalizedString("mySite.siteActions.personalizeHome", value: "Personalize home", comment: "Menu title for the personalize home option")
}
