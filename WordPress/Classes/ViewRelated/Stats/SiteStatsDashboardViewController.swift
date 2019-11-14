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

    // MARK: - Properties

    @IBOutlet weak var filterTabBar: FilterTabBar!

    private var insightsTableViewController = SiteStatsInsightsTableViewController.loadFromStoryboard()
    private var periodTableViewController = SiteStatsPeriodTableViewController.loadFromStoryboard()
    private var pageViewController: UIPageViewController?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFilterBar()
        restoreSelectedPeriodFromUserDefaults()
        addWillEnterForegroundObserver()
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
            updatePeriodView(oldSelectedPeriod: currentSelectedPeriod, withDate: periodTableViewController.selectedDate)
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
        static let userDefaultsKey = "LastSelectedStatsPeriodType"
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
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        currentSelectedPeriod = StatsPeriodType(rawValue: filterBar.selectedIndex) ?? StatsPeriodType.insights
    }

}

// MARK: - User Defaults Support

private extension SiteStatsDashboardViewController {

    func saveSelectedPeriodToUserDefaults() {
        UserDefaults.standard.set(currentSelectedPeriod.rawValue, forKey: Constants.userDefaultsKey)
    }

    func getSelectedPeriodFromUserDefaults() -> StatsPeriodType {
        return StatsPeriodType(rawValue: UserDefaults.standard.integer(forKey: Constants.userDefaultsKey)) ?? .insights
    }

    func restoreSelectedPeriodFromUserDefaults() {
        currentSelectedPeriod = getSelectedPeriodFromUserDefaults()
    }

    func updatePeriodView(oldSelectedPeriod: StatsPeriodType, withDate periodDate: Date? = nil) {
        let selectedPeriodChanged = currentSelectedPeriod != oldSelectedPeriod
        let previousSelectedPeriodWasInsights = oldSelectedPeriod == .insights
        let pageViewControllerIsEmpty = pageViewController?.viewControllers?.isEmpty ?? true

        switch currentSelectedPeriod {
        case .insights:
            if selectedPeriodChanged || pageViewControllerIsEmpty {
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

            periodTableViewController.selectedDate = periodDate ?? StatsDataHelper.currentDateForSite()
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
