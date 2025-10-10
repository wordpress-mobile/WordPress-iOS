import Foundation
import UIKit
import SwiftUI
import WordPressData
import WordPressShared
import WordPressAPI
import WordPressCore

// MARK: - BlogDetailsViewController (Misc)

extension BlogDetailsViewController {
    @objc public var shouldShowSubscribersRow: Bool {
        FeatureFlag.newsletterSubscribers.enabled && blog.supports(.people)
    }

    @objc public func makeSubscribersRow() -> BlogDetailsRow {
        BlogDetailsRow(title: Strings.subscribers, image: UIImage(named: "wpl-mail") ?? UIImage()) { [weak self] in
            guard let self else { return }
            guard let blog = SubscribersBlog(blog: self.blog) else {
                return wpAssertionFailure("incompatible blog")
            }
            let vc = SubscribersViewController(blog: blog)
            self.presentationDelegate?.presentBlogDetailsViewController(vc)
        }
    }

    @objc public func makePeopleRow() -> BlogDetailsRow {
        let row = BlogDetailsRow(
            title: shouldShowSubscribersRow ? Strings.users : NSLocalizedString("People", comment: "Noun. Title. Links to the people management feature."),
            image: UIImage(named: "site-menu-people") ?? UIImage()
        ) { [weak self] in
            self?.showPeople()
        }
        row.accessibilityIdentifier = "Users Row"
        return row
    }

    @objc public func isDashboardEnabled() -> Bool {
        return JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() && blog.isAccessibleThroughWPCom()
    }

    @objc public func confirmRemoveSite() {
        let blogService = BlogService(coreDataStack: ContextManager.shared)
        blogService.remove(blog)

        WordPressAppDelegate.shared?.trackLogoutIfNeeded()

        if AppConfiguration.isWordPress {
            ContentMigrationCoordinator.shared.cleanupExportedDataIfNeeded()
        }

        // Delete local data after removing the last site
        if !AccountHelper.isLoggedIn {
            AccountHelper.deleteAccountData()
        }

        navigationController?.popToRootViewController(animated: true)
    }

    @objc public func shouldShowJetpackInstallCard() -> Bool {
        !WPDeviceIdentification.isiPad() && JetpackInstallPluginHelper.shouldShowCard(for: blog)
    }

    @objc public func shouldShowBlaze() -> Bool {
        BlazeHelper.isBlazeFlagEnabled() && self.blog.supports(.blaze)
    }
}

// MARK: - BlogDetailsViewController (Navigation)

extension BlogDetailsViewController {
    @objc public func showDashboard() {
        if isSidebarModeEnabled {
            let controller = MySiteViewController.make(forBlog: blog, isSidebarModeEnabled: true)
            presentationDelegate?.presentBlogDetailsViewController(controller)
        } else {
            let controller = BlogDashboardViewController(blog: blog, embeddedInScrollView: false)
            controller.navigationItem.largeTitleDisplayMode = .never
            controller.extendedLayoutIncludesOpaqueBars = true
            presentationDelegate?.presentBlogDetailsViewController(controller)
        }
    }

    @objc(showPostListFromSource:)
    public func showPostList(from source: BlogDetailsNavigationSource) {
        trackEvent(.openedPosts, from: source)
        let controller = PostListViewController.controllerWithBlog(blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        presentationDelegate?.presentBlogDetailsViewController(controller)
    }

    @objc(showPageListFromSource:)
    public func showPageList(from source: BlogDetailsNavigationSource) {
        trackEvent(.openedPages, from: source)
        let controller = PageListViewController.controllerWithBlog(blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        presentationDelegate?.presentBlogDetailsViewController(controller)
    }

    @objc(showMediaLibraryFromSource:)
    public func showMediaLibrary(from source: BlogDetailsNavigationSource) {
        showMediaLibrary(from: source, showPicker: false)
    }

    @objc(showMediaLibraryFromSource:showPicker:)
    public func showMediaLibrary(from source: BlogDetailsNavigationSource, showPicker: Bool) {
        trackEvent(.openedMediaLibrary, from: source)
        let controller = SiteMediaViewController(blog: blog, showPicker: showPicker)
        presentationDelegate?.presentBlogDetailsViewController(controller)
    }

    @objc(showSettingsFromSource:)
    public func showSettings(from source: BlogDetailsNavigationSource) {
        trackEvent(.openedSiteSettings, from: source)

        guard let settingsVC = SiteSettingsViewController(blog: blog) else {
            return wpAssertionFailure("failed to instantiate")
        }
        settingsVC.navigationItem.largeTitleDisplayMode = .never

        if isSidebarModeEnabled {
            let navigationController = UINavigationController(rootViewController: settingsVC)

            settingsVC.navigationItem.rightBarButtonItem = UIBarButtonItem(
                systemItem: .done,
                primaryAction: UIAction { [weak self] _ in
                    self?.tableView.deselectSelectedRowWithAnimation(true)
                    self?.dismiss(animated: true, completion: nil)
                }
            )
            navigationController.modalPresentationStyle = .formSheet
            present(navigationController, animated: true, completion: nil)
            presentedSiteSettingsViewController = navigationController
            navigationController.presentationController?.delegate = self
        } else {
            presentationDelegate?.presentBlogDetailsViewController(settingsVC)
        }
    }

    @objc @discardableResult
    public func showMe() -> MeViewController {
        let controller = MeViewController()
        presentationDelegate?.presentBlogDetailsViewController(controller)
        return controller
    }

    @objc public func showPeople() {
        guard let controller = PeopleViewController.withJPBannerForBlog(blog) else {
            return wpAssertionFailure("failed to instantiate")
        }
        presentationDelegate?.presentBlogDetailsViewController(controller)
    }

    @objc public func showActivity() {
        let controller = ActivityLogsViewController(blog: blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        presentationDelegate?.presentBlogDetailsViewController(controller)

        WPAnalytics.track(.activityLogViewed, withProperties: [WPAppAnalyticsKeyTapSource: "site_menu"])
    }

    @objc public func showBlaze() {
        BlazeEventsTracker.trackEntryPointTapped(for: .menuItem)

        if RemoteFeature.enabled(.blazeManageCampaigns) {
            let controller = BlazeCampaignsViewController(source: .menuItem, blog: blog)
            presentationDelegate?.presentBlogDetailsViewController(controller)
        } else {
            BlazeFlowCoordinator.presentBlaze(in: self, source: .menuItem, blog: blog, post: nil)
        }
    }

    @objc public func showScan() {
        let scanVC = JetpackScanViewController.withJPBannerForBlog(blog)
        presentationDelegate?.presentBlogDetailsViewController(scanVC)
    }

    @objc public func showBackup() {
        let controller = BackupsViewController(blog: blog)
        controller.navigationItem.largeTitleDisplayMode = .never

        presentationDelegate?.presentBlogDetailsViewController(controller)

        WPAnalytics.track(.backupListOpened)
    }

    @objc public func showThemes() {
        WPAppAnalytics.track(.themesAccessedThemeBrowser, blog: blog)
        let themesVC = ThemeBrowserViewController.browserWithBlog(blog)
        themesVC.hidesBottomBarWhenPushed = true
        let jpWrappedViewController = themesVC.withJPBanner()
        presentationDelegate?.presentBlogDetailsViewController(jpWrappedViewController)
    }

    @objc public func showMenus() {
        WPAppAnalytics.track(.menusAccessed, blog: blog)
        let menusVC = MenusViewController.withJPBannerForBlog(blog)
        presentationDelegate?.presentBlogDetailsViewController(menusVC)
    }

    @objc(showCommentsFromSource:)
    public func showComments(from source: BlogDetailsNavigationSource) {
        trackEvent(.openedComments, from: source)

        guard let commentsVC = CommentsViewController(blog: blog) else {
            return wpAssertionFailure("failed to instantiate")
        }
        commentsVC.navigationItem.largeTitleDisplayMode = .never

        if isSidebarModeEnabled {
            commentsVC.isSidebarModeEnabled = true

            if #available(iOS 26, *) {
                presentationDelegate?.presentBlogDetailsViewController(commentsVC)
            } else {
                let splitVC = UISplitViewController(style: .doubleColumn)
                splitVC.presentsWithGesture = false
                splitVC.preferredDisplayMode = .oneBesideSecondary
                splitVC.preferredPrimaryColumnWidth = 320
                splitVC.minimumPrimaryColumnWidth = 375
                splitVC.maximumPrimaryColumnWidth = 400
                splitVC.setViewController(commentsVC, for: .primary)

                let noSelectionVC = UIViewController()
                noSelectionVC.view.backgroundColor = .systemBackground
                splitVC.setViewController(noSelectionVC, for: .secondary)
                presentationDelegate?.presentBlogDetailsViewController(splitVC)
            }
        } else {
            presentationDelegate?.presentBlogDetailsViewController(commentsVC)
        }
    }

    @objc public func showPlugins() {
        WPAppAnalytics.track(.openedPluginDirectory, blog: blog)

        if Feature.enabled(.pluginManagementOverhaul) {
            showManagePluginsScreen()
            return
        }

        guard let site = JetpackSiteRef(blog: blog) else {
            return wpAssertionFailure("unexpected blog")
        }
        let controller = PluginDirectoryViewController(site: site)
        controller.navigationItem.largeTitleDisplayMode = .never
        presentationDelegate?.presentBlogDetailsViewController(controller)
    }

    @objc(showStatsFromSource:)
    public func showStats(from source: BlogDetailsNavigationSource) {
        trackEvent(.statsAccessed, from: source)

        let statsVC = makeStatsVC()

        // Calling `showDetailViewController:sender:` should do this automatically for us,
        // but when showing stats from our 3D Touch shortcut iOS sometimes incorrectly
        // presents the stats view controller as modal instead of pushing it. As a
        // workaround for now, we'll manually decide whether to push or use `showDetail`.
        // @frosty 2016-09-05
        if let splitViewController, splitViewController.isCollapsed {
            navigationController?.pushViewController(statsVC, animated: true)
        } else {
            presentationDelegate?.presentBlogDetailsViewController(statsVC)
        }
    }

    private func makeStatsVC() -> UIViewController {
        guard JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() else {
            return MovedToJetpackViewController(source: .stats)
        }
        return StatsHostingViewController.makeStatsViewController(for: blog)
    }

    @objc(showDomainsFromSource:)
    public func showDomains(from source: BlogDetailsNavigationSource) {
        guard let presentationDelegate else {
            return wpAssertionFailure("presentationDelegate mising")
        }
        DomainsDashboardCoordinator.presentDomainsDashboard(with: presentationDelegate, source: source.string, blog: blog)
    }

    @objc public func showJetpackSettings() {
        let controller = JetpackSettingsViewController(blog: blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        presentationDelegate?.presentBlogDetailsViewController(controller)
    }

    @objc(showSharingFromSource:)
    public func showSharing(from source: BlogDetailsNavigationSource) {
        let sharingVC: UIViewController

        if !blog.supportsPublicize() {
            // if publicize is disabled, show the sharing buttons settings.
            sharingVC = SharingButtonsViewController(blog: blog)
        } else {
            sharingVC = SharingViewController(blog: blog, delegate: nil)
        }

        trackEvent(.openedSharingManagement, from: source)
        sharingVC.navigationItem.largeTitleDisplayMode = .never
        presentationDelegate?.presentBlogDetailsViewController(sharingVC)
    }

    @objc(showViewSiteFromSource:)
    public func showViewSite(from source: BlogDetailsNavigationSource) {
        trackEvent(.openedViewSite, from: source)

        guard let string = blog.homeURL, let homeURL = URL(string: string as String) else {
            return wpAssertionFailure("homeURL missing")
        }

        let webViewController = WebViewControllerFactory.controller(
            url: homeURL,
            blog: blog,
            source: "my_site_view_site",
            withDeviceModes: true,
            onClose: nil
        )

        let navigationController = UINavigationController(rootViewController: webViewController)
        if traitCollection.userInterfaceIdiom == .pad {
            navigationController.modalPresentationStyle = .fullScreen
        }
        present(navigationController, animated: true, completion: nil)
    }

    @objc public func showViewAdmin() {
        WPAppAnalytics.track(.openedViewAdmin, blog: blog)

        let dashboardPath: String
        if blog.isHostedAtWPcom, let hostname = blog.hostname {
            dashboardPath = "\(Constants.calypsoDashboardPath)\(hostname)"
        } else {
            dashboardPath = blog.adminUrl(withPath: "")
        }

        guard let url = URL(string: dashboardPath) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    @objc public func showSiteMonitoring() {
        showSiteMonitoring(selectedTab: nil)
    }

    @objc public func showSiteMonitoring(selectedTab: NSNumber?) {
        let selectedTab = selectedTab.flatMap { SiteMonitoringTab(rawValue: $0.intValue) }
        let controller = SiteMonitoringViewController(blog: blog, selectedTab: selectedTab)
        presentationDelegate?.presentBlogDetailsViewController(controller)
    }

    @objc public func showApplicationPasswords() {
        let feature = NSLocalizedString("applicationPasswordRequired.feature.users", value: "Application Passwords Management", comment: "Feature name for managing application passwords in the app")
        let view = ApplicationPasswordRequiredView(blog: blog, localizedFeatureName: feature, presentingViewController: self) {
            ApplicationTokenListView(dataProvider: ApplicationPasswordService(api: $0))
        }
        presentationDelegate?.presentBlogDetailsViewController(UIHostingController(rootView: view))
    }
}

// MARK: - BlogDetailsViewController (Tracking)

extension BlogDetailsViewController {
    @objc public func trackEvent(_ event: WPAnalyticsStat, from source: BlogDetailsNavigationSource) {
        var properties: [String: Any] = [
            WPAppAnalyticsKeyTapSource: source.string,
            WPAppAnalyticsKeyTabSource: "site_menu"
        ]
        if event == .statsAccessed, FeatureFlag.newStats.enabled {
            properties[WPAnalyticsEvent.isNewStatsKey] = "1"
        }
        WPAppAnalytics.track(event, properties: properties, blog: blog)
    }
}

@objc public enum BlogDetailsNavigationSource: Int {
    case button = 0
    case row = 1
    case link = 2
    case widget = 3
    case onboarding = 4
    case notification = 5
    case shortcut = 6
    case todayStatsCard = 7

    var string: String {
        switch self {
        case .row: "row"
        case .link: "link"
        case .button: "button"
        case .widget: "widget"
        case .onboarding: "onboarding"
        case .notification: "notification"
        case .shortcut: "shortcut"
        case .todayStatsCard: "todays_stats_card"
        default: ""
        }
    }
}

private enum Constants {
    static let calypsoDashboardPath = "https://wordpress.com/home/"
}

private enum Strings {
    static let users = NSLocalizedString("mySite.menu.users", value: "Users", comment: "Title for the menu item")
    static let subscribers = NSLocalizedString("mySite.menu.subscribers", value: "Subscribers", comment: "Title for the menu item")
}

// Necessary data that's required to get an application application from a given site.
@objc public class ApplicationPasswordAuthenticationInfo: NSObject {
    public let siteAddress: String
    public let siteDetails: AutoDiscoveryAttemptSuccess
    public let siteUsername: String

    public init(siteAddress: String, siteDetails: AutoDiscoveryAttemptSuccess, siteUsername: String) {
        self.siteAddress = siteAddress
        self.siteDetails = siteDetails
        self.siteUsername = siteUsername
    }
}
