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
        let sections = [
            makePrimarySection(),
            makeSecondarySection(),
            makeTertiarySection()
        ]
        return sections.compactMap { $0 }
    }

    private func makePrimarySection() -> UIMenu {
        let menuItems = [
            MenuItem.visitSite({ [weak self] in self?.visitSiteTapped() }),
            MenuItem.shareSite { [weak self] in self?.buttonShareSiteTapped() },
            MenuItem.switchSite({ [weak self] in self?.siteSwitcherTapped() })
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

    private func buttonShareSiteTapped() {
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

    func addSiteTapped(siteType: AddSiteAlertViewModel.Selection) {
        WPAnalytics.trackEvent(.mySiteHeaderAddSiteTapped, properties: ["siteType": siteType.rawValue])

        switch siteType {
        case .dotCom: launchSiteCreation()
        case .selfHosted: launchLoginForSelfHostedSite()
        }
    }

    private func launchSiteCreation() {
        let viewController = presentedViewController ?? self
        let source = "my_site"
        JetpackFeaturesRemovalCoordinator.presentSiteCreationOverlayIfNeeded(in: viewController, source: source, onDidDismiss: {
            guard JetpackFeaturesRemovalCoordinator.siteCreationPhase() != .two else {
                return
            }

            // Display site creation flow if not in phase two
            let wizardLauncher = SiteCreationWizardLauncher()
            guard let wizard = wizardLauncher.ui else {
                return
            }
            RootViewCoordinator.shared.isSiteCreationActive = true
            viewController.present(wizard, animated: true)
            SiteCreationAnalyticsHelper.trackSiteCreationAccessed(source: source)
        })
    }

    private func launchLoginForSelfHostedSite() {
        guard FeatureFlag.authenticateUsingApplicationPassword.enabled else {
            WordPressAuthenticator.showLoginForSelfHostedSite(presentedViewController ?? self)
            return
        }

        launchApplicationPasswordAuthenticationForSelfHostedSite()
    }

    private func launchApplicationPasswordAuthenticationForSelfHostedSite() {
        guard let navigationController = presentedViewController?.navigationController ?? (presentedViewController as? UINavigationController) else {
            return
        }

        guard let window = navigationController.view.window else {
            return
        }

        let client = LoginClient(session: URLSession(configuration: .ephemeral))
        let view = LoginWithUrlView(client: client, anchor: window) { [weak navigationController] credentials in
            navigationController?.dismiss(animated: true)

            WordPressAuthenticator.shared.delegate!.sync(credentials: .init(wporg: credentials)) {
                NotificationCenter.default.post(
                    name: Foundation.Notification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification),
                    object: nil
                )
            }
        }

        navigationController.pushViewController(UIHostingController(rootView: view), animated: true)
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

    private func defaultAccount() -> WPAccount? {
        try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
    }
}

private enum MenuItem {
    case visitSite(_ handler: () -> Void)
    case shareSite(_ handler: () -> Void)
    case addSite(_ handler: () -> Void)
    case switchSite(_ handler: () -> Void)
    case siteTitle(_ handler: () -> Void)
    case personalizeHome(_ handler: () -> Void)

    var title: String {
        switch self {
        case .visitSite: return Strings.visitSite
        case .shareSite: return Strings.shareSite
        case .addSite: return Strings.addSite
        case .switchSite: return Strings.switchSite
        case .siteTitle: return Strings.siteTitle
        case .personalizeHome: return Strings.personalizeHome
        }
    }

    var icon: UIImage? {
        switch self {
        case .visitSite: return UIImage(systemName: "safari")
        case .shareSite: return UIImage(systemName: "square.and.arrow.up")
        case .addSite: return UIImage(systemName: "plus")
        case .switchSite: return UIImage(systemName: "arrow.triangle.swap")
        case .siteTitle: return UIImage(systemName: "character")
        case .personalizeHome: return UIImage(systemName: "slider.horizontal.3")
        }
    }

    var toAction: UIAction {
        switch self {
        case .visitSite(let handler),
             .shareSite(let handler),
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
    static let shareSite = NSLocalizedString("mySite.siteActions.shareSite", value: "Share site", comment: "Menu title for the share site option")
    static let switchSite = NSLocalizedString("mySite.siteActions.switchSite", value: "Switch site", comment: "Menu title for the switch site option")
    static let siteTitle = NSLocalizedString("mySite.siteActions.siteTitle", value: "Change site title", comment: "Menu title for the change site title option")
    static let siteIcon = NSLocalizedString("mySite.siteActions.siteIcon", value: "Change site icon", comment: "Menu title for the change site icon option")
    static let personalizeHome = NSLocalizedString("mySite.siteActions.personalizeHome", value: "Personalize home", comment: "Menu title for the personalize home option")
}
