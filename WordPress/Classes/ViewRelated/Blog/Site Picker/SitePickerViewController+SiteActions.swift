import UIKit
import SwiftUI
import WordPressAuthenticator

extension SitePickerViewController {

    func makeSiteActionsMenu() -> UIMenu? {
        UIMenu(options: .displayInline, children: [
            UIDeferredMenuElement.uncached { [weak self] in
                $0(self?.makeSections() ?? [])
            }
        ])
    }

    private func makeSections() -> [UIMenu] {
        [
            makePrimarySection(),
            makeSecondarySection(),
            makeTertiarySection()
        ]
    }

    private func makePrimarySection() -> UIMenu {
        var menuItems = [
            MenuItem.visitSite({ [weak self] in self?.visitSiteTapped() }),
            MenuItem.addSite({ [weak self] in self?.addSiteTapped()} ),
        ]
        if numberOfBlogs() > 1 {
            menuItems.append(MenuItem.switchSite({ [weak self] in self?.siteSwitcherTapped() }))
        }
        return UIMenu(options: .displayInline, children: menuItems.map { $0.toAction })
    }

    private func makeSecondarySection() -> UIMenu {
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

    // MARK: - Add site

    private func addSiteTapped() {
        let canCreateWPComSite = defaultAccount() != nil
        let canAddSelfHostedSite = AppConfiguration.showAddSelfHostedSiteButton

        // Launch wp.com site creation if the user can't add self-hosted sites
        if canCreateWPComSite && !canAddSelfHostedSite {
            launchSiteCreation()
            return
        }

        showAddSiteActionSheet(from: blogDetailHeaderView.titleView.siteActionButton,
                               canCreateWPComSite: canCreateWPComSite,
                               canAddSelfHostedSite: canAddSelfHostedSite)

        WPAnalytics.trackEvent(.mySiteHeaderAddSiteTapped)
    }

    private func showAddSiteActionSheet(from sourceView: UIView, canCreateWPComSite: Bool, canAddSelfHostedSite: Bool) {
        let actionSheet = AddSiteAlertFactory().makeAddSiteAlert(
            source: "my_site",
            canCreateWPComSite: canCreateWPComSite,
            createWPComSite: { [weak self] in self?.launchSiteCreation() },
            canAddSelfHostedSite: canAddSelfHostedSite,
            addSelfHostedSite: { [weak self] in self?.launchLoginForSelfHostedSite() }
        )

        actionSheet.popoverPresentationController?.sourceView = sourceView
        actionSheet.popoverPresentationController?.sourceRect = sourceView.bounds
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up

        parent?.present(actionSheet, animated: true)
    }

    private func launchSiteCreation() {
        guard let parent = parent as? MySiteViewController else {
            return
        }
        parent.launchSiteCreation(source: "my_site")
    }

    private func launchLoginForSelfHostedSite() {
        WordPressAuthenticator.showLoginForSelfHostedSite(self)
    }

    // MARK: - Personalize home

    private func personalizeHomeTapped() {
        guard let siteID = blog.dotComID?.intValue else {
            return DDLogError("Failed to show dashboard personalization screen: siteID is missing")
        }

        let viewController = UIHostingController(rootView: NavigationView {
            BlogDashboardPersonalizationView(viewModel: .init(blog: self.blog, service: .init(siteID: siteID)))
        }.navigationViewStyle(.stack)) // .stack is required for iPad
        if UIDevice.isPad() {
            viewController.modalPresentationStyle = .formSheet
        }
        present(viewController, animated: true)

        WPAnalytics.trackEvent(.mySiteHeaderPersonalizeHomeTapped)
    }

    // MARK: - Helpers

    private func numberOfBlogs() -> Int {
        defaultAccount()?.blogs?.count ?? 0
    }

    private func defaultAccount() -> WPAccount? {
        try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
    }
}

private enum MenuItem {
    case visitSite(_ handler: () -> Void)
    case addSite(_ handler: () -> Void)
    case switchSite(_ handler: () -> Void)
    case siteTitle(_ handler: () -> Void)
    case personalizeHome(_ handler: () -> Void)

    var title: String {
        switch self {
        case .visitSite: return Strings.visitSite
        case .addSite: return Strings.addSite
        case .switchSite: return Strings.switchSite
        case .siteTitle: return Strings.siteTitle
        case .personalizeHome: return Strings.personalizeHome
        }
    }

    var icon: UIImage? {
        switch self {
        case .visitSite: return UIImage(systemName: "safari")
        case .addSite: return UIImage(systemName: "plus")
        case .switchSite: return UIImage(systemName: "arrow.triangle.swap")
        case .siteTitle: return UIImage(systemName: "character")
        case .personalizeHome: return UIImage(systemName: "slider.horizontal.3")
        }
    }

    var toAction: UIAction {
        switch self {
        case .visitSite(let handler),
             .addSite(let handler),
             .switchSite(let handler),
             .siteTitle(let handler),
             .personalizeHome(let handler):
            return UIAction(title: title, image: icon) { _ in handler() }
        }
    }
}

private enum Strings {
    static let visitSite = NSLocalizedString("mySite.siteActions.visitSite", value: "Visit site", comment: "Menu title for the visit site option")
    static let addSite = NSLocalizedString("mySite.siteActions.addSite", value: "Add site", comment: "Menu title for the add site option")
    static let switchSite = NSLocalizedString("mySite.siteActions.switchSite", value: "Switch site", comment: "Menu title for the switch site option")
    static let siteTitle = NSLocalizedString("mySite.siteActions.siteTitle", value: "Change site title", comment: "Menu title for the change site title option")
    static let siteIcon = NSLocalizedString("mySite.siteActions.siteIcon", value: "Change site icon", comment: "Menu title for the change site icon option")
    static let personalizeHome = NSLocalizedString("mySite.siteActions.personalizeHome", value: "Personalize home", comment: "Menu title for the personalize home option")
}
