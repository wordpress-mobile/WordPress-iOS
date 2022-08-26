import UIKit

enum StatsPeriodType: Int, FilterTabBarItem, CaseIterable {
    case insights = 0
    case days
    case weeks
    case months
    case years

    // This is public as it is needed by FilterTabBarItem.
    var title: String {
        switch self {
        case .insights: return NSLocalizedString("Insights", comment: "Title of Insights stats filter.")
        case .days: return NSLocalizedString("Days", comment: "Title of Days stats filter.")
        case .weeks: return NSLocalizedString("Weeks", comment: "Title of Weeks stats filter.")
        case .months: return NSLocalizedString("Months", comment: "Title of Months stats filter.")
        case .years: return NSLocalizedString("Years", comment: "Title of Years stats filter.")
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
        default:
            return nil
        }
    }
}

fileprivate extension StatsPeriodType {
    static let allPeriods = StatsPeriodType.allCases

    var analyticsAccessEvent: WPAnalyticsStat {
        switch self {
        case .insights: return .statsInsightsAccessed
        case .days:     return .statsPeriodDaysAccessed
        case .weeks:    return .statsPeriodWeeksAccessed
        case .months:   return .statsPeriodMonthsAccessed
        case .years:    return .statsPeriodYearsAccessed
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
    private var periodTableViewController = SiteStatsPeriodTableViewController.loadFromStoryboard()
    private var pageViewController: UIPageViewController?

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
        configurePeriodTableViewController()
        setupFilterBar()
        restoreSelectedDateFromUserDefaults()
        restoreSelectedPeriodFromUserDefaults()
        addWillEnterForegroundObserver()
        configureNavBar()
        view.accessibilityIdentifier = "stats-dashboard"
    }

    func configureInsightsTableView() {
        insightsTableViewController.tableStyle = FeatureFlag.statsNewAppearance.enabled ? .insetGrouped : .grouped
        insightsTableViewController.bannerView = jetpackBannerView
    }

    private func configurePeriodTableViewController() {
        periodTableViewController.bannerView = jetpackBannerView
    }

    func configureNavBar() {
        parent?.navigationItem.rightBarButtonItem = currentSelectedPeriod == .insights ? manageInsightsButton : nil
    }

    func configureJetpackBanner() {
        guard JetpackBrandingVisibility.all.enabled else {
            jetpackBannerView.removeFromSuperview()
            return
        }
        jetpackBannerView.buttonAction = { [unowned self] in
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

    struct Constants {
        static let progressViewInitialProgress = Float(0.03)
        static let progressViewHideDelay = 1
        static let progressViewHideDuration = 0.15
    }

    var currentSelectedPeriod: StatsPeriodType {
        get {
            let selectedIndex = filterTabBar?.selectedIndex ?? StatsPeriodType.insights.rawValue
            return StatsPeriodType(rawValue: selectedIndex) ?? .insights
        }
        set {
            filterTabBar?.setSelectedIndex(newValue.rawValue)
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
        filterTabBar.items = StatsPeriodType.allPeriods
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
        filterTabBar.accessibilityIdentifier = "site-stats-dashboard-filter-bar"
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        currentSelectedPeriod = StatsPeriodType(rawValue: filterBar.selectedIndex) ?? StatsPeriodType.insights

        configureNavBar()
    }

}

// MARK: - User Defaults Support

private extension SiteStatsDashboardViewController {

    func saveSelectedPeriodToUserDefaults() {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue,
              !insightsTableViewController.isGrowAudienceShowing else {
            return
        }

        let key = Self.lastSelectedStatsPeriodTypeKey(forSiteID: siteID)
        UserPersistentStoreFactory.instance().set(currentSelectedPeriod.rawValue, forKey: key)
    }

    func getSelectedPeriodFromUserDefaults() -> StatsPeriodType {

        guard let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue,
              let periodType = StatsPeriodType(rawValue: UserPersistentStoreFactory.instance().integer(forKey: Self.lastSelectedStatsPeriodTypeKey(forSiteID: siteID))) else {
            return .insights
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
        periodTableViewController.selectedDate = getLastSelectedDateFromUserDefaults()
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
        default:
            if previousSelectedPeriodWasInsights || pageViewControllerIsEmpty {
                pageViewController?.setViewControllers([periodTableViewController],
                                                       direction: .forward,
                                                       animated: false)
            }

            if periodTableViewController.selectedDate == nil
                || selectedPeriodChanged {

                periodTableViewController.selectedDate = StatsDataHelper.currentDateForSite()
            }

            let selectedPeriod = StatsPeriodUnit(rawValue: currentSelectedPeriod.rawValue - 1) ?? .day
            periodTableViewController.selectedPeriod = selectedPeriod
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
