import UIKit

enum StatsPeriodType: Int, FilterTabBarItem, CaseIterable {
    case insights = 0
    case days
    case weeks
    case months
    case years
    case traffic

    // This is public as it is needed by FilterTabBarItem.
    var title: String {
        switch self {
        case .insights: return NSLocalizedString("Insights", comment: "Title of Insights stats filter.")
        case .days: return NSLocalizedString("Days", comment: "Title of Days stats filter.")
        case .weeks: return NSLocalizedString("Weeks", comment: "Title of Weeks stats filter.")
        case .months: return NSLocalizedString("Months", comment: "Title of Months stats filter.")
        case .years: return NSLocalizedString("Years", comment: "Title of Years stats filter.")
        case .traffic: return NSLocalizedString("stats.dashboard.tab.traffic", value: "Traffic", comment: "Title of Traffic stats tab.")
        }
    }

    init?(from string: String) {
        switch string {
        case "day":
            self = .days
        case "week":
            self = .weeks
        case "month":
            self = .months
        case "year":
            self = .years
        case "insights":
            self = .insights
        case "traffic":
            self = .traffic
        default:
            return nil
        }
    }
}

fileprivate extension StatsPeriodType {
    static var displayedPeriods: [StatsPeriodType] {
        if RemoteFeatureFlag.statsTrafficTab.enabled() {
            return [.traffic, .insights]
        } else {
            return [.insights, .days, .weeks, .months, .years]
        }
    }

    var analyticsAccessEvent: WPAnalyticsStat {
        switch self {
        case .insights: return .statsInsightsAccessed
        case .days:     return .statsPeriodDaysAccessed
        case .weeks:    return .statsPeriodWeeksAccessed
        case .months:   return .statsPeriodMonthsAccessed
        case .years:    return .statsPeriodYearsAccessed
        case .traffic:  return .noStat // TODO
        }
    }
}

class SiteStatsDashboardViewController: UIViewController {

    // MARK: - Keys

    static func lastSelectedStatsPeriodTypeKey(forSiteID siteID: Int) -> String {
        return "LastSelectedStatsPeriodType-\(siteID)"
    }

    static let lastSelectedStatsDateKey = "LastSelectedStatsDate"

    // MARK: - Properties

    @IBOutlet weak var filterTabBar: FilterTabBar!
    @IBOutlet weak var jetpackBannerView: JetpackBannerView!

    private var insightsTableViewController = SiteStatsInsightsTableViewController.loadFromStoryboard()
    private lazy var periodTableViewControllerDeprecated = SiteStatsPeriodTableViewControllerDeprecated.loadFromStoryboard()
    private lazy var trafficTableViewController = SiteStatsPeriodTableViewController()
    private var pageViewController: UIPageViewController?
    private lazy var displayedPeriods: [StatsPeriodType] = StatsPeriodType.displayedPeriods

    @objc lazy var manageInsightsButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
                image: .gridicon(.cog),
                style: .plain,
                target: self,
                action: #selector(manageInsightsButtonTapped))
        button.accessibilityHint = NSLocalizedString("Tap to customize insights", comment: "Accessibility hint to customize insights")
        return button
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        configureJetpackBanner()
        configureInsightsTableView()
        configurePeriodTableViewControllerDeprecated()
        configureTrafficTableViewController()
        setupFilterBar()
        restoreSelectedDateFromUserDefaults()
        restoreSelectedPeriodFromUserDefaults()
        addWillEnterForegroundObserver()
        configureNavBar()
        view.accessibilityIdentifier = "stats-dashboard"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        JetpackFeaturesRemovalCoordinator.presentOverlayIfNeeded(in: self, source: .stats)
    }

    func configureInsightsTableView() {
        insightsTableViewController.tableStyle = AppConfiguration.statsRevampV2Enabled ? .insetGrouped : .grouped
        insightsTableViewController.bannerView = jetpackBannerView
    }

    private func configurePeriodTableViewControllerDeprecated() {
        periodTableViewControllerDeprecated.bannerView = jetpackBannerView
    }

    private func configureTrafficTableViewController() {
        trafficTableViewController.bannerView = jetpackBannerView
    }

    func configureNavBar() {
        parent?.navigationItem.rightBarButtonItem = currentSelectedPeriod == .insights ? manageInsightsButton : nil
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
            updatePeriodView(oldSelectedPeriod: currentSelectedPeriod)
        }
    }
}

extension SiteStatsDashboardViewController: StatsForegroundObservable {
    func reloadStatsData() {
        updatePeriodView(oldSelectedPeriod: currentSelectedPeriod)
    }
}

// MARK: - Private Extension

private extension SiteStatsDashboardViewController {
    var currentSelectedPeriod: StatsPeriodType {
        get {
            let selectedIndex = filterTabBar?.selectedIndex ?? 0
            return displayedPeriods[selectedIndex]
        }
        set {
            let index = displayedPeriods.firstIndex(of: newValue) ?? 0
            filterTabBar?.setSelectedIndex(index)
            let oldSelectedPeriod = getSelectedPeriodFromUserDefaults()
            updatePeriodView(oldSelectedPeriod: oldSelectedPeriod)
            saveSelectedPeriodToUserDefaults()
            trackAccessEvent()
        }
    }
}

// MARK: - FilterTabBar Support

private extension SiteStatsDashboardViewController {

    func setupFilterBar() {
        WPStyleGuide.Stats.configureFilterTabBar(filterTabBar)
        filterTabBar.items = displayedPeriods
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
        filterTabBar.accessibilityIdentifier = "site-stats-dashboard-filter-bar"
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        currentSelectedPeriod = displayedPeriods[filterBar.selectedIndex]

        configureNavBar()
    }

}

// MARK: - User Defaults Support

private extension SiteStatsDashboardViewController {

    func saveSelectedPeriodToUserDefaults() {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue else {
            return
        }

        let key = Self.lastSelectedStatsPeriodTypeKey(forSiteID: siteID)

        guard !insightsTableViewController.isGrowAudienceShowing else {
            UserPersistentStoreFactory.instance().set(StatsPeriodType.insights.rawValue, forKey: key)
            return
        }

        UserPersistentStoreFactory.instance().set(currentSelectedPeriod.rawValue, forKey: key)
    }

    func getSelectedPeriodFromUserDefaults() -> StatsPeriodType {

        guard let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue,
              let periodType = StatsPeriodType(rawValue: UserPersistentStoreFactory.instance().integer(forKey: Self.lastSelectedStatsPeriodTypeKey(forSiteID: siteID))) else {
            return displayedPeriods[0]
        }

        return periodType
    }

    func getLastSelectedDateFromUserDefaults() -> Date? {
        UserPersistentStoreFactory.instance().object(forKey: Self.lastSelectedStatsDateKey) as? Date
    }

    func removeLastSelectedDateFromUserDefaults() {
        UserPersistentStoreFactory.instance().removeObject(forKey: Self.lastSelectedStatsDateKey)
    }

    func restoreSelectedDateFromUserDefaults() {
        periodTableViewControllerDeprecated.selectedDate = getLastSelectedDateFromUserDefaults()
        trafficTableViewController.selectedDate = getLastSelectedDateFromUserDefaults()
        removeLastSelectedDateFromUserDefaults()
    }

    func restoreSelectedPeriodFromUserDefaults() {
        currentSelectedPeriod = getSelectedPeriodFromUserDefaults()
    }

    func updatePeriodView(oldSelectedPeriod: StatsPeriodType) {
        let selectedPeriodChanged = currentSelectedPeriod != oldSelectedPeriod
        let previousSelectedPeriodWasInsights = oldSelectedPeriod == .insights
        let pageViewControllerIsEmpty = pageViewController?.viewControllers?.isEmpty ?? true
        let isGrowAudienceShowingOnInsights = insightsTableViewController.isGrowAudienceShowing

        switch currentSelectedPeriod {
        case .insights:
            if selectedPeriodChanged || pageViewControllerIsEmpty || isGrowAudienceShowingOnInsights {
                pageViewController?.setViewControllers([insightsTableViewController],
                                                       direction: .forward,
                                                       animated: false)
            }
            insightsTableViewController.refreshInsights()
        case .traffic:
            if previousSelectedPeriodWasInsights || pageViewControllerIsEmpty {
                pageViewController?.setViewControllers([trafficTableViewController],
                                                       direction: .forward,
                                                       animated: false)
            }

            if trafficTableViewController.selectedDate == nil {
                trafficTableViewController.selectedDate = StatsDataHelper.currentDateForSite()
            }

            let selectedPeriod = StatsPeriodUnit(rawValue: currentSelectedPeriod.rawValue - 1) ?? .day
            trafficTableViewController.selectedPeriod = selectedPeriod
        case .days, .weeks, .months, .years:
            if previousSelectedPeriodWasInsights || pageViewControllerIsEmpty {
                pageViewController?.setViewControllers([periodTableViewControllerDeprecated],
                                                       direction: .forward,
                                                       animated: false)
            }

            if periodTableViewControllerDeprecated.selectedDate == nil
                || selectedPeriodChanged {

                periodTableViewControllerDeprecated.selectedDate = StatsDataHelper.currentDateForSite()
            }

            let selectedPeriod = StatsPeriodUnit(rawValue: currentSelectedPeriod.rawValue - 1) ?? .day
            periodTableViewControllerDeprecated.selectedPeriod = selectedPeriod
        }
    }

}

// MARK: - Tracks Support

private extension SiteStatsDashboardViewController {

    func captureAnalyticsEvent(_ event: WPAnalyticsStat) {
        if let blogIdentifier = SiteStatsInformation.sharedInstance.siteID {
            WPAppAnalytics.track(event, withBlogID: blogIdentifier)
        } else {
            WPAppAnalytics.track(event)
        }
    }

    func trackAccessEvent() {
        let event = currentSelectedPeriod.analyticsAccessEvent
        captureAnalyticsEvent(event)
    }
}
