import UIKit
import WordPressShared

enum StatsTabType: Int, FilterTabBarItem, CaseIterable {
    case insights = 0
    case traffic
    case subscribers

    // This is public as it is needed by FilterTabBarItem.
    var title: String {
        switch self {
        case .insights: return NSLocalizedString("Insights", comment: "Title of Insights stats filter.")
        case .traffic: return NSLocalizedString("stats.dashboard.tab.traffic", value: "Traffic", comment: "Title of Traffic stats tab.")
        case .subscribers: return NSLocalizedString("stats.dashboard.tab.subscribers", value: "Subscribers", comment: "Title of Subscribers stats tab.")
        }
    }

    init?(from string: String) {
        switch string {
        case "insights":
            self = .insights
        case "traffic":
            self = .traffic
        case "subscribers":
            self = .subscribers
        default:
            return nil
        }
    }
}

fileprivate extension StatsTabType {
    static var displayedTabs: [StatsTabType] {
        return [.traffic, .insights, .subscribers]
    }

    var analyticsAccessEvent: WPAnalyticsStat? {
        switch self {
        case .insights: return .statsInsightsAccessed
        case .traffic:  return nil
        case .subscribers: return .statsSubscribersAccessed
        }
    }
}

class SiteStatsDashboardViewController: UIViewController {
    static let lastSelectedStatsDateKey = "LastSelectedStatsDate"

    // MARK: - Properties

    @IBOutlet weak var filterTabBar: FilterTabBar!
    @IBOutlet weak var jetpackBannerView: JetpackBannerView!

    private var pageViewController: UIPageViewController?
    private lazy var displayedTabs: [StatsTabType] = StatsTabType.displayedTabs

    @objc lazy var manageInsightsButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
                image: UIImage(systemName: "gearshape"),
                style: .plain,
                target: self,
                action: #selector(manageInsightsButtonTapped))
        button.accessibilityHint = NSLocalizedString("Tap to customize insights", comment: "Accessibility hint to customize insights")
        return button
    }()

    // MARK: - Stats View Controllers

    private lazy var insightsTableViewController = {
        let viewController = SiteStatsInsightsTableViewController.loadFromStoryboard()
        viewController.tableStyle = .insetGrouped
        viewController.bannerView = jetpackBannerView
        return viewController
    }()

    private lazy var trafficTableViewController = {
        let date: Date
        if let selectedDate = SiteStatsDashboardPreferences.getLastSelectedDateFromUserDefaults() {
            date = selectedDate
        } else {
            date = StatsDataHelper.currentDateForSite()
        }

        let currentPeriod = SiteStatsDashboardPreferences.getSelectedPeriodUnit() ?? .day

        let viewController = SiteStatsPeriodTableViewController(date: date, period: currentPeriod)
        viewController.bannerView = jetpackBannerView
        return viewController
    }()

    private lazy var subscribersViewController = {
        let viewModel = StatsSubscribersViewModel()
        return StatsSubscribersViewController(viewModel: viewModel)
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        // Important to make navigation bar match the filter bar
        view.backgroundColor = .systemBackground

        configureJetpackBanner()
        setupFilterBar()
        restoreSelectedDateFromUserDefaults()
        restoreSelectedTabFromUserDefaults()
        configureNavBar()
        view.accessibilityIdentifier = "stats-dashboard"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addWillEnterForegroundObserver()
        JetpackFeaturesRemovalCoordinator.presentOverlayIfNeeded(in: self, source: .stats)
    }

    func configureNavBar() {
        parent?.navigationItem.rightBarButtonItem = currentSelectedTab == .insights ? manageInsightsButton : nil
    }

    func configureJetpackBanner() {
        guard JetpackBrandingVisibility.all.enabled else {
            jetpackBannerView.removeFromSuperview()
            return
        }
        let textProvider = JetpackBrandingTextProvider(screen: JetpackBannerScreen.stats)
        jetpackBannerView.configure(title: textProvider.brandingText()) { [unowned self] in
            JetpackBrandingCoordinator.presentOverlay(from: self)
            JetpackBrandingAnalyticsHelper.trackJetpackPoweredBannerTapped(screen: .stats)
        }
    }

    @objc func manageInsightsButtonTapped() {
        insightsTableViewController.showAddInsightView(source: "nav_bar")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeWillEnterForegroundObserver()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let pageViewController as UIPageViewController:
            self.pageViewController = pageViewController
        default:
            break
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if traitCollection.verticalSizeClass == .regular, traitCollection.horizontalSizeClass == .compact {
            updatePeriodView(oldSelectedTab: currentSelectedTab)
        }
    }
}

extension SiteStatsDashboardViewController: StatsForegroundObservable {
    func reloadStatsData() {
        updatePeriodView(oldSelectedTab: currentSelectedTab)
    }
}

// MARK: - Private Extension

private extension SiteStatsDashboardViewController {
    var currentSelectedTab: StatsTabType {
        get {
            let selectedIndex = filterTabBar?.selectedIndex ?? 0
            return displayedTabs[selectedIndex]
        }
        set {
            let index = displayedTabs.firstIndex(of: newValue) ?? 0
            filterTabBar?.setSelectedIndex(index)
            let oldSelectedPeriod = getSelectedTabFromUserDefaults()
            updatePeriodView(oldSelectedTab: oldSelectedPeriod)
            saveSelectedPeriodToUserDefaults()
            trackAccessEvent()
        }
    }
}

// MARK: - FilterTabBar Support

private extension SiteStatsDashboardViewController {

    func setupFilterBar() {
        WPStyleGuide.Stats.configureFilterTabBar(filterTabBar)
        filterTabBar.isAutomaticTabSizingStyleEnabled = true
        filterTabBar.items = displayedTabs
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
        filterTabBar.accessibilityIdentifier = "site-stats-dashboard-filter-bar"
        filterTabBar.backgroundColor = .systemBackground
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        currentSelectedTab = displayedTabs[filterBar.selectedIndex]

        configureNavBar()
    }
}

// MARK: - User Defaults Support

private extension SiteStatsDashboardViewController {

    func saveSelectedPeriodToUserDefaults() {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue else {
            return
        }

        guard !insightsTableViewController.isGrowAudienceShowing else {
            SiteStatsDashboardPreferences.setSelected(tabType: .insights, siteID: siteID)
            return
        }

        SiteStatsDashboardPreferences.setSelected(tabType: currentSelectedTab, siteID: siteID)
    }

    func getSelectedTabFromUserDefaults() -> StatsTabType {
        guard let tabType = SiteStatsDashboardPreferences.getSelectedTabType() else {
            return displayedTabs[0]
        }

        return tabType
    }

    func restoreSelectedDateFromUserDefaults() {
        SiteStatsDashboardPreferences.removeLastSelectedDateFromUserDefaults()
    }

    func restoreSelectedTabFromUserDefaults() {
        currentSelectedTab = getSelectedTabFromUserDefaults()
    }

    func updatePeriodView(oldSelectedTab: StatsTabType) {
        let selectedPeriodChanged = currentSelectedTab != oldSelectedTab
        let pageViewControllerIsEmpty = pageViewController?.viewControllers?.isEmpty ?? true
        let isGrowAudienceShowingOnInsights = insightsTableViewController.isGrowAudienceShowing

        switch currentSelectedTab {
        case .insights:
            if selectedPeriodChanged || pageViewControllerIsEmpty || isGrowAudienceShowingOnInsights {
                pageViewController?.setViewControllers([insightsTableViewController],
                                                       direction: .forward,
                                                       animated: false)
            } else {
                insightsTableViewController.refreshInsights()
            }
        case .traffic:
            if oldSelectedTab != .traffic || pageViewControllerIsEmpty {
                pageViewController?.setViewControllers([trafficTableViewController],
                                                       direction: .forward,
                                                       animated: false)
            } else {
                trafficTableViewController.refreshData()
            }
        case .subscribers:
            if oldSelectedTab != .subscribers || pageViewControllerIsEmpty {
                pageViewController?.setViewControllers([subscribersViewController],
                                                       direction: .forward,
                                                       animated: false)
            } else {
                subscribersViewController.refreshData()
            }
        }
    }

}

// MARK: - Tracks Support

private extension SiteStatsDashboardViewController {

    func captureAnalyticsEvent(_ event: WPAnalyticsStat) {
        if let blogIdentifier = SiteStatsInformation.sharedInstance.siteID {
            WPAppAnalytics.track(event, blogID: blogIdentifier)
        } else {
            WPAppAnalytics.track(event)
        }
    }

    func trackAccessEvent() {
        if let event = currentSelectedTab.analyticsAccessEvent {
            captureAnalyticsEvent(event)
        }
    }
}

// MARK: - Preferences

struct SiteStatsDashboardPreferences {
    static func setSelected(tabType: StatsTabType, siteID: Int? = nil) {
        guard let siteID = siteID ?? SiteStatsInformation.sharedInstance.siteID?.intValue else { return }

        let periodKey = lastSelectedStatsTabTypeKey(forSiteID: siteID)
        UserPersistentStoreFactory.instance().set(tabType.rawValue, forKey: periodKey)
    }

    static func setSelected(periodUnit: StatsPeriodUnit) {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue else { return }

        let unitKey = lastSelectedStatsUnitTypeKey(forSiteID: siteID)
        UserPersistentStoreFactory.instance().set(periodUnit.rawValue, forKey: unitKey)
    }

    static func getSelectedTabType() -> StatsTabType? {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue else { return nil }

        let key = Self.lastSelectedStatsTabTypeKey(forSiteID: siteID)

        guard let tabRawValue = UserPersistentStoreFactory.instance().object(forKey: key) as? Int else {
            return nil
        }

        return StatsTabType(rawValue: tabRawValue)
    }

    static func getSelectedPeriodUnit() -> StatsPeriodUnit? {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue else { return nil }

        let key = Self.lastSelectedStatsUnitTypeKey(forSiteID: siteID)
        return StatsPeriodUnit(rawValue: UserPersistentStoreFactory.instance().integer(forKey: key))
    }

    static func getLastSelectedDateFromUserDefaults() -> Date? {
        UserPersistentStoreFactory.instance().object(forKey: Self.lastSelectedStatsDateKey) as? Date
    }

    static func removeLastSelectedDateFromUserDefaults() {
        UserPersistentStoreFactory.instance().removeObject(forKey: Self.lastSelectedStatsDateKey)
    }

    // MARK: - Keys

    private static func lastSelectedStatsTabTypeKey(forSiteID siteID: Int) -> String {
        return "LastSelectedStatsTabType-\(siteID)"
    }

    private static func lastSelectedStatsUnitTypeKey(forSiteID siteID: Int) -> String {
        return "LastSelectedStatsUnitType-\(siteID)"
    }

    private static let lastSelectedStatsDateKey = "LastSelectedStatsDate"
}
