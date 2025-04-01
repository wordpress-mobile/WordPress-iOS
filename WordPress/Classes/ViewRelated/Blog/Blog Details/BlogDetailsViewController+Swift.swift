import Foundation
import WordPressShared

// MARK: - BlogDetailsViewController (Misc)

extension BlogDetailsViewController {
    @objc func isDashboardEnabled() -> Bool {
        return JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() && blog.isAccessibleThroughWPCom()
    }
}

// MARK: - BlogDetailsViewController (Navigation)

extension BlogDetailsViewController {
    @objc func showDashboard() {
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
    func showPostList(from source: BlogDetailsNavigationSource) {
        trackEvent(.openedPosts, from: source)
        let controller = PostListViewController.controllerWithBlog(blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        presentationDelegate?.presentBlogDetailsViewController(controller)
    }

    @objc(showPageListFromSource:)
    func showPageList(from source: BlogDetailsNavigationSource) {
        trackEvent(.openedPages, from: source)
        let controller = PageListViewController.controllerWithBlog(blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        presentationDelegate?.presentBlogDetailsViewController(controller)
    }

    @objc(showMediaLibraryFromSource:)
    func showMediaLibrary(from source: BlogDetailsNavigationSource) {
        showMediaLibrary(from: source, showPicker: false)
    }

    @objc(showMediaLibraryFromSource:showPicker:)
    func showMediaLibrary(from source: BlogDetailsNavigationSource, showPicker: Bool) {
        trackEvent(.openedMediaLibrary, from: source)
        let controller = SiteMediaViewController(blog: blog, showPicker: showPicker)
        presentationDelegate?.presentBlogDetailsViewController(controller)
    }

    @objc(showSettingsFromSource:)
    func showSettings(from source: BlogDetailsNavigationSource) {
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

    @objc
    @discardableResult func showMe() -> MeViewController {
        let controller = MeViewController()
        presentationDelegate?.presentBlogDetailsViewController(controller)
        return controller
    }

    @objc func showPeople() {
        guard let controller = PeopleViewController.withJPBannerForBlog(blog) else {
            return wpAssertionFailure("failed to instantiate")
        }
        presentationDelegate?.presentBlogDetailsViewController(controller)
    }

    @objc func showActivity() {
        guard let controller = JetpackActivityLogViewController(blog: blog) else {
            return wpAssertionFailure("failed to instantiate")
        }
        controller.navigationItem.largeTitleDisplayMode = .never
        presentationDelegate?.presentBlogDetailsViewController(controller)

        WPAnalytics.track(.activityLogViewed, withProperties: [WPAppAnalyticsKeyTapSource: "site_menu"])
    }

    @objc func showBlaze() {
        BlazeEventsTracker.trackEntryPointTapped(for: .menuItem)

        if RemoteFeature.enabled(.blazeManageCampaigns) {
            let controller = BlazeCampaignsViewController(source: .menuItem, blog: blog)
            presentationDelegate?.presentBlogDetailsViewController(controller)
        } else {
            BlazeFlowCoordinator.presentBlaze(in: self, source: .menuItem, blog: blog, post: nil)
        }
    }

    @objc func showScan() {
        let scanVC = JetpackScanViewController.withJPBannerForBlog(blog)
        presentationDelegate?.presentBlogDetailsViewController(scanVC)
    }

    @objc func showBackup() {
        guard let backupListVC = BackupListViewController.withJPBannerForBlog(blog) else {
            return wpAssertionFailure("failed to instantiate")
        }
        presentationDelegate?.presentBlogDetailsViewController(backupListVC)
    }

    @objc func showThemes() {
        WPAppAnalytics.track(.themesAccessedThemeBrowser, blog: blog)
        let themesVC = ThemeBrowserViewController.browserWithBlog(blog)
        themesVC.hidesBottomBarWhenPushed = true
        let jpWrappedViewController = themesVC.withJPBanner()
        presentationDelegate?.presentBlogDetailsViewController(jpWrappedViewController)
    }

    @objc func showMenus() {
        WPAppAnalytics.track(.menusAccessed, blog: blog)
        let menusVC = MenusViewController.withJPBannerForBlog(blog)
        presentationDelegate?.presentBlogDetailsViewController(menusVC)
    }

    @objc(showCommentsFromSource:)
    func showComments(from source: BlogDetailsNavigationSource) {
        trackEvent(.openedComments, from: source)

        guard let commentsVC = CommentsViewController(blog: blog) else {
            return wpAssertionFailure("failed to instantiate")
        }
        commentsVC.navigationItem.largeTitleDisplayMode = .never

        if isSidebarModeEnabled {
            commentsVC.isSidebarModeEnabled = true

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
        } else {
            presentationDelegate?.presentBlogDetailsViewController(commentsVC)
        }
    }

    @objc func showPlugins() {
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
    func showStats(from source: BlogDetailsNavigationSource) {
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

        let statsVC = StatsViewController()
        statsVC.blog = blog
        statsVC.hidesBottomBarWhenPushed = true
        statsVC.navigationItem.largeTitleDisplayMode = .never
        return statsVC
    }

    @objc(showDomainsFromSource:)
    func showDomains(from source: BlogDetailsNavigationSource) {
        guard let presentationDelegate else {
            return wpAssertionFailure("presentationDelegate mising")
        }
        DomainsDashboardCoordinator.presentDomainsDashboard(with: presentationDelegate, source: source.string, blog: blog)
    }

    @objc func showJetpackSettings() {
        let controller = JetpackSettingsViewController(blog: blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        presentationDelegate?.presentBlogDetailsViewController(controller)
    }

    @objc(showSharingFromSource:)
    func showSharing(from source: BlogDetailsNavigationSource) {
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
    func showViewSite(from source: BlogDetailsNavigationSource) {
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

    @objc func showViewAdmin() {
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
}

// MARK: - BlogDetailsViewController (Tracking)

extension BlogDetailsViewController {
    @objc func trackEvent(_ event: WPAnalyticsStat, from source: BlogDetailsNavigationSource) {
        WPAppAnalytics.track(event, properties: [
            WPAppAnalyticsKeyTapSource: source.string,
            WPAppAnalyticsKeyTabSource: "site_menu"
        ], blog: blog)
    }
}

@objc enum BlogDetailsNavigationSource: Int {
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
