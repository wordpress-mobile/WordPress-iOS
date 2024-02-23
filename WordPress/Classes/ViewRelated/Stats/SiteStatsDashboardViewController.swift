import UIKit
import SwiftUI

enum StatsTabType: Int, FilterTabBarItem, CaseIterable {
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

    var unit: StatsPeriodUnit? {
        switch self {
        case .days:
            return .day
        case .weeks:
            return .week
        case .months:
            return .month
        case .years:
            return .year
        default:
            return nil
        }
    }
}

fileprivate extension StatsTabType {
    static var displayedTabs: [StatsTabType] {
        if RemoteFeatureFlag.statsTrafficTab.enabled() {
            return [.traffic, .insights]
        } else {
            return [.insights, .days, .weeks, .months, .years]
        }
    }

    var analyticsAccessEvent: WPAnalyticsStat? {
        switch self {
        case .insights: return .statsInsightsAccessed
        case .days:     return .statsPeriodDaysAccessed
        case .weeks:    return .statsPeriodWeeksAccessed
        case .months:   return .statsPeriodMonthsAccessed
        case .years:    return .statsPeriodYearsAccessed
        case .traffic:  return nil
        }
    }
}

class SiteStatsDashboardViewController: UIViewController {
    static let lastSelectedStatsDateKey = "LastSelectedStatsDate"

    // MARK: - Properties

    @IBOutlet weak var filterTabBar: FilterTabBar!
    @IBOutlet weak var jetpackBannerView: JetpackBannerView!

    private var insightsTableViewController = SiteStatsInsightsTableViewController.loadFromStoryboard()
    private lazy var periodTableViewControllerDeprecated = SiteStatsPeriodTableViewControllerDeprecated.loadFromStoryboard()
    private lazy var trafficTableViewController = {
        let selectedDate: Date
        if let date = SiteStatsDashboardPreferences.getLastSelectedDateFromUserDefaults() {
            selectedDate = date
        } else {
            selectedDate = StatsDataHelper.currentDateForSite()
        }

        let selectedPeriodUnit = SiteStatsDashboardPreferences.getSelectedPeriodUnit() ?? .day

        return SiteStatsPeriodTableViewController(selectedDate: selectedDate, selectedPeriod: selectedPeriodUnit)
    }()
    private var pageViewController: UIPageViewController?
    private lazy var displayedTabs: [StatsTabType] = StatsTabType.displayedTabs

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
        restoreSelectedTabFromUserDefaults()
        addWillEnterForegroundObserver()
        configureNavBar()
        view.accessibilityIdentifier = "stats-dashboard"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        JetpackFeaturesRemovalCoordinator.presentOverlayIfNeeded(in: self, source: .stats)
    }

    func configureInsightsTableView() {
        insightsTableViewController.tableStyle = .insetGrouped
        insightsTableViewController.bannerView = jetpackBannerView
    }

    private func configurePeriodTableViewControllerDeprecated() {
        periodTableViewControllerDeprecated.bannerView = jetpackBannerView
    }

    private func configureTrafficTableViewController() {
        trafficTableViewController.bannerView = jetpackBannerView
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
        filterTabBar.items = displayedTabs
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
        filterTabBar.accessibilityIdentifier = "site-stats-dashboard-filter-bar"
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
        periodTableViewControllerDeprecated.selectedDate = SiteStatsDashboardPreferences.getLastSelectedDateFromUserDefaults()
        SiteStatsDashboardPreferences.removeLastSelectedDateFromUserDefaults()
    }

    func restoreSelectedTabFromUserDefaults() {
        currentSelectedTab = getSelectedTabFromUserDefaults()
    }

    func updatePeriodView(oldSelectedTab: StatsTabType) {
        let selectedPeriodChanged = currentSelectedTab != oldSelectedTab
        let previousSelectedPeriodWasInsights = oldSelectedTab == .insights
        let pageViewControllerIsEmpty = pageViewController?.viewControllers?.isEmpty ?? true
        let isGrowAudienceShowingOnInsights = insightsTableViewController.isGrowAudienceShowing

        switch currentSelectedTab {
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

            let selectedPeriod = StatsPeriodUnit(rawValue: currentSelectedTab.rawValue - 1) ?? .day
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

        let unitKey = lastSelectedStatsUnitTypeKey(forSiteID: siteID)
        if let unit = tabType.unit {
            UserPersistentStoreFactory.instance().set(unit.rawValue, forKey: unitKey)
        }
    }

    static func setSelected(periodUnit: StatsPeriodUnit) {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue else { return }

        let unitKey = lastSelectedStatsTabTypeKey(forSiteID: siteID)
        UserPersistentStoreFactory.instance().set(periodUnit.rawValue, forKey: unitKey)
    }

    static func getSelectedTabType() -> StatsTabType? {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue else { return nil }

        let key = Self.lastSelectedStatsTabTypeKey(forSiteID: siteID)
        return StatsTabType(rawValue: UserPersistentStoreFactory.instance().integer(forKey: key))
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
