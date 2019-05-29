import UIKit

class SiteStatsDashboardViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet weak var filterTabBar: FilterTabBar!
    @IBOutlet weak var insightsContainerView: UIView!
    @IBOutlet weak var statsContainerView: UIView!

    private var insightsTableViewController: SiteStatsInsightsTableViewController?
    private var periodTableViewController: SiteStatsPeriodTableViewController?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFilterBar()
        getSelectedPeriodFromUserDefaults()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let insightsTableVC = segue.destination as? SiteStatsInsightsTableViewController {
            insightsTableViewController = insightsTableVC
        }

        if let periodTableVC = segue.destination as? SiteStatsPeriodTableViewController {
            periodTableViewController = periodTableVC
        }
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

    enum StatsPeriodType: Int, FilterTabBarItem {
        case insights = 0
        case days
        case weeks
        case months
        case years

        static let allPeriods = [StatsPeriodType.insights, .days, .weeks, .months, .years]

        var title: String {
            switch self {
            case .insights: return NSLocalizedString("Insights", comment: "Title of Insights stats filter.")
            case .days: return NSLocalizedString("Days", comment: "Title of Days stats filter.")
            case .weeks: return NSLocalizedString("Weeks", comment: "Title of Weeks stats filter.")
            case .months: return NSLocalizedString("Months", comment: "Title of Months stats filter.")
            case .years: return NSLocalizedString("Years", comment: "Title of Years stats filter.")
            }
        }

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

    var currentSelectedPeriod: StatsPeriodType {
        get {
            let selectedIndex = filterTabBar?.selectedIndex ?? StatsPeriodType.insights.rawValue
            return StatsPeriodType(rawValue: selectedIndex) ?? .insights
        }
        set {
            filterTabBar?.setSelectedIndex(newValue.rawValue)
            setContainerViewVisibility()
            updatePeriodView()
            saveSelectedPeriodToUserDefaults()
            trackAccessEvent()
        }
    }

    func setContainerViewVisibility() {
        statsContainerView.isHidden = currentSelectedPeriod == .insights
        insightsContainerView.isHidden = !statsContainerView.isHidden
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

    func getSelectedPeriodFromUserDefaults() {
        currentSelectedPeriod = StatsPeriodType(rawValue: UserDefaults.standard.integer(forKey: Constants.userDefaultsKey)) ?? .insights
    }

    func updatePeriodView() {

        guard currentSelectedPeriod != .insights else {
            return
        }

        periodTableViewController?.selectedDate = Date()
        let selectedPeriod = StatsPeriodUnit(rawValue: currentSelectedPeriod.rawValue - 1) ?? .day
        periodTableViewController?.selectedPeriod = selectedPeriod
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
