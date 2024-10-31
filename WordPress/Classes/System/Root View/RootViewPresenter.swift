import Foundation

protocol RootViewPresenter: AnyObject {
    var rootViewController: UIViewController { get }
    func currentlySelectedScreen() -> String

    func currentlyVisibleBlog() -> Blog?
    func showMySitesTab()
    func showBlogDetails(for blog: Blog, then subsection: BlogDetailsSubsection?, userInfo: [AnyHashable: Any])

    func showReader(path: ReaderNavigationPath?)

    func showNotificationsTab(completion: ((NotificationsViewController) -> Void)?)

    func showMeScreen(completion: ((MeViewController) -> Void)?)
}

// MARK: - RootViewPresenter (Extensions)

extension RootViewPresenter {

    // MARK: Sites

    func showBlogDetails(for blog: Blog) {
        showBlogDetails(for: blog, then: nil, userInfo: [:])
    }

    func showBlogDetails(for blog: Blog, then subsection: BlogDetailsSubsection) {
        showBlogDetails(for: blog, then: subsection, userInfo: [:])
    }

    func showStats(for blog: Blog, source: BlogDetailsNavigationSource? = nil, tab: StatsTabType? = nil, unit: StatsPeriodUnit? = nil, date: Date? = nil) {
        guard JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures() else {
            return showJetpackOverlayForDisabledEntryPoint()
        }
        if let date = date {
            UserPersistentStoreFactory.instance().set(date, forKey: SiteStatsDashboardViewController.lastSelectedStatsDateKey)
        }
        if let siteID = blog.dotComID?.intValue, let tab = tab {
            SiteStatsDashboardPreferences.setSelected(tabType: tab, siteID: siteID)
        }
        if let unit = unit {
            SiteStatsDashboardPreferences.setSelected(periodUnit: unit)
        }
        var userInfo: [AnyHashable: Any] = [:]
        if let source {
            userInfo[BlogDetailsViewController.userInfoSourceKey()] = NSNumber(value: source.rawValue)
        }
        showBlogDetails(for: blog, then: .stats)
    }

    // MARK: Reader

    func showReader() {
        showReader(path: nil)
    }

    // MARK: Notifications

    func showNotificationsTab() {
        showNotificationsTab(completion: nil)
    }

    func showNotificationsTabForNote(withID notificationID: String) {
        showNotificationsTab {
            $0.showDetailsForNotificationWithID(notificationID)
        }
    }

    func popNotificationsTabToRoot() {
        showNotificationsTab {
            $0.navigationController?.popToRootViewController(animated: false)
        }
    }

    func switchNotificationsTabToNotificationSettings() {
        showNotificationsTab {
            $0.navigationController?.popToRootViewController(animated: false)
            $0.showNotificationSettings()
        }
    }

    // MARK: Me

    func showMeScreen() {
        showMeScreen(completion: nil)
    }

    // MARK: Misc

    func showJetpackOverlayForDisabledEntryPoint() {
        JetpackFeaturesRemovalCoordinator.presentOverlayIfNeeded(
            in: rootViewController,
            source: .disabledEntryPoint,
            blog: currentlyVisibleBlog()
        )
    }
}
