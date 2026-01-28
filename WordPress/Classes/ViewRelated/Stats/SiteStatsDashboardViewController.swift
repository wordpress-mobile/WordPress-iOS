import UIKit
import WordPressKit
import WordPressShared
import WordPressData
import WordPressUI
import Combine
import TipKit
import BuildSettingsKit
import JetpackStats

enum StatsTabType: Int, AdaptiveTabBarItem, CaseIterable {
    case insights = 0
    case traffic
    case subscribers
    case ads

    var id: StatsTabType { self }

    var localizedTitle: String {
        switch self {
        case .insights: return NSLocalizedString("Insights", comment: "Title of Insights stats filter.")
        case .traffic: return NSLocalizedString("stats.dashboard.tab.traffic", value: "Traffic", comment: "Title of Traffic stats tab.")
        case .subscribers: return NSLocalizedString("stats.dashboard.tab.subscribers", value: "Subscribers", comment: "Title of Subscribers stats tab.")
        case .ads: return NSLocalizedString("stats.dashboard.tab.ads", value: "Ads", comment: "Title of Ads stats tab.")
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
        case "ads":
            self = .ads
        default:
            return nil
        }
    }

    var analyticsAccessEvent: WPAnalyticsStat? {
        switch self {
        case .insights: return .statsInsightsAccessed
        case .traffic: return nil
        case .subscribers: return .statsSubscribersAccessed
        case .ads: return nil
        }
    }
}

public class SiteStatsDashboardViewController: UIViewController {
    static let lastSelectedStatsDateKey = "LastSelectedStatsDate"

    // MARK: - Helpers

    /// Returns the current blog from SiteStatsInformation if available
    private static func currentBlog() -> Blog? {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID,
              let blog = Blog.lookup(withID: siteID, in: ContextManager.shared.mainContext) else {
            return nil
        }
        return blog
    }

    // MARK: - Properties

    private let containerView = UIView()

    private var currentChildViewController: UIViewController?
    private lazy var displayedTabs: [StatsTabType] = {
        var tabs: [StatsTabType] = [.traffic, .insights, .subscribers]

        // Add Ads tab if feature flag is enabled and WordAds is active on the site
        if FeatureFlag.statsAds.enabled,
           let blog = Self.currentBlog(),
           blog.isWordAdsActive() {
            tabs.append(.ads)
        }

        return tabs
    }()
    private var tipObserver: TipObserver?
    private var isUsingMockData = UITestConfigurator.isEnabled(.useMockData)
    private var navigationItemObserver: NSKeyValueObservation?
    private let filterBarController = AdaptiveTabBarController<StatsTabType>()

    @objc public lazy var manageInsightsButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
                image: UIImage(systemName: "gearshape"),
                style: .plain,
                target: self,
                action: #selector(manageInsightsButtonTapped))
        button.accessibilityHint = NSLocalizedString("Tap to customize insights", comment: "Accessibility hint to customize insights")
        return button
    }()

    private lazy var statsMenuButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            menu: createStatsMenu()
        )
        return button
    }()

    // MARK: - Stats View Controllers

    private lazy var insightsTableViewController = SiteStatsInsightsTableViewController()

    private lazy var trafficTableViewController: UIViewController = {
        // If new stats is enabled, show StatsHostingViewController instead
        if FeatureFlag.newStats.enabled {
            return createNewTrafficViewController() ?? createClassicTrafficViewController()
        } else {
            return createClassicTrafficViewController()
        }
    }()

    private func createNewTrafficViewController() -> UIViewController? {
        if isUsingMockData {
            // Create with demo context for mock data
            return StatsHostingViewController.makeNewTrafficViewController(blog: nil, parentViewController: self, isDemo: true)
        } else {
            guard let blog = Self.currentBlog() else {
                return nil
            }
            return StatsHostingViewController.makeNewTrafficViewController(blog: blog, parentViewController: self, isDemo: false)
        }
    }

    private func createClassicTrafficViewController() -> UIViewController {
        let date: Date
        if let selectedDate = SiteStatsDashboardPreferences.getLastSelectedDateFromUserDefaults() {
            date = selectedDate
        } else {
            date = StatsDataHelper.currentDateForSite()
        }

        let currentPeriod = SiteStatsDashboardPreferences.getSelectedPeriodUnit() ?? .day

        return SiteStatsPeriodTableViewController(date: date, period: currentPeriod)
    }

    private lazy var subscribersViewController = {
        let viewModel = StatsSubscribersViewModel()
        return StatsSubscribersViewController(viewModel: viewModel)
    }()

    private lazy var adsViewController: UIViewController? = {
        guard let blog = Self.currentBlog() else {
            return nil
        }
        return StatsHostingViewController.makeAdsViewController(blog: blog, parentViewController: self)
    }()

    // MARK: - View

    deinit {
        navigationItemObserver?.invalidate()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Important to make navigation bar match the filter bar
        view.backgroundColor = .systemBackground

        setupViews()
        setupFilterBar()
        restoreSelectedDateFromUserDefaults()
        restoreSelectedTabFromUserDefaults()
        configureNavBar()
        view.accessibilityIdentifier = "stats-dashboard"
    }

    private func setupViews() {
        view.addSubview(containerView)
        containerView.pinEdges()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addWillEnterForegroundObserver()
        JetpackFeaturesRemovalCoordinator.presentOverlayIfNeeded(in: self, source: .stats)
    }

    func configureNavBar() {
        // Clean up previous observer
        navigationItemObserver?.invalidate()
        navigationItemObserver = nil

        switch currentSelectedTab {
        case .insights:
            parent?.navigationItem.trailingItemGroups = [
                UIBarButtonItemGroup.fixedGroup(items: [manageInsightsButton])
            ]
        case .traffic:
            // Always show the menu for switching between stats experiences
            statsMenuButton.menu = createStatsMenu()

            // Set up observer for navigation item changes
            navigationItemObserver = trafficTableViewController.navigationItem.observe(\.trailingItemGroups, options: [.initial, .new]) { [weak self] navigationItem, _ in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.updateParentNavigationItems(with: self.trafficTableViewController)
                }
            }

            // Show tip for new stats if available and not enabled
            if !FeatureFlag.newStats.enabled {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    self.showNewStatsTip()
                }
            }
        case .ads:
            parent?.navigationItem.trailingItemGroups = []
        default:
            parent?.navigationItem.trailingItemGroups = []
        }
    }

    private func updateParentNavigationItems(with childVC: UIViewController) {
        parent?.navigationItem.trailingItemGroups = childVC.navigationItem.trailingItemGroups + [
            UIBarButtonItemGroup.fixedGroup(items: [statsMenuButton])
        ]
    }

    @objc public func manageInsightsButtonTapped() {
        insightsTableViewController.showAddInsightView(source: "nav_bar")
    }

    private func createStatsMenu() -> UIMenu {
        var menuElements: [UIMenuElement] = []

        if FeatureFlag.newStats.enabled {
            // Main actions
            var mainActions: [UIMenuElement] = []

            // Add "Switch to Classic Stats" option when new stats is enabled
            let switchToClassicAction = UIAction(
                title: Strings.switchToClassic,
                image: UIImage(systemName: "arrow.uturn.backward")
            ) { [weak self] _ in
                self?.disableNewStats()
            }
            mainActions.append(switchToClassicAction)

            // Add "Send Feedback" option
            let sendFeedbackAction = UIAction(
                title: Strings.sendFeedback,
                image: UIImage(systemName: "envelope")
            ) { [weak self] _ in
                self?.showFeedbackView()
            }
            mainActions.append(sendFeedbackAction)

            menuElements.append(contentsOf: mainActions)

            // Debug section (only in debug builds)
            if BuildConfiguration.current == .debug {
                let toggleDataSource = UIAction(
                    title: isUsingMockData ? "Use Real Data" : "Use Mock Data",
                    image: UIImage(systemName: "arrow.triangle.2.circlepath")
                ) { [weak self] _ in
                    self?.toggleDataSource()
                }

                let debugMenu = UIMenu(title: "Debug", options: .displayInline, children: [toggleDataSource])
                menuElements.append(debugMenu)
            }
        } else {
            // Add "Try New Stats" option if feature is available but not enabled
            let tryNewStatsAction = UIAction(
                title: Strings.tryNewStats,
                image: UIImage(systemName: "sparkles")
            ) { [weak self] _ in
                self?.enableNewStats()
            }
            menuElements.append(tryNewStatsAction)
        }

        return UIMenu(children: menuElements)
    }

    private func enableNewStats() {
        WPAnalytics.track(.statsNewStatsEnabled)

        FeatureFlagOverrideStore().override(FeatureFlag.newStats, withValue: true)

        // Update the traffic view controller to show new stats
        guard let trafficVC = createNewTrafficViewController() else {
            return
        }

        trafficTableViewController = trafficVC
        showChildViewController(trafficTableViewController)
        configureNavBar()
    }

    private func disableNewStats() {
        WPAnalytics.track(.statsNewStatsDisabled)

        FeatureFlagOverrideStore().override(FeatureFlag.newStats, withValue: false)

        trafficTableViewController = createClassicTrafficViewController()
        showChildViewController(trafficTableViewController)
        configureNavBar()
    }

    private func toggleDataSource() {
        isUsingMockData.toggle()

        // Update the traffic view controller with new data source
        guard let trafficVC = createNewTrafficViewController() else {
            return
        }

        trafficTableViewController = trafficVC
        showChildViewController(trafficTableViewController)

        // Update menu to reflect new state
        statsMenuButton.menu = createStatsMenu()

        // Show notice indicating the change
        let message = isUsingMockData ? "Using mock data" : "Using real data"
        Notice(title: message).post()
    }

    private func showNewStatsTip() {
        tipObserver?.cancel()
        tipObserver = registerTipPopover(
            AppTips.NewStatsTip(),
            sourceItem: statsMenuButton,
            arrowDirection: .up
        ) { [weak self] action in
            guard let self else { return }
            if action.id == "try-new-stats" {
                self.enableNewStats()
                if self.presentedViewController is TipUIPopoverViewController {
                    self.dismiss(animated: true)
                }
            }
        }
    }

    private func showFeedbackView() {
        present(SubmitFeedbackViewController(source: "new_stats", feedbackPrefix: "Stats"), animated: true)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeWillEnterForegroundObserver()
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
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
            filterBarController.selection ?? .traffic
        }
        set {
            filterBarController.selection = newValue
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
        wpAssert(parent != nil)
        filterBarController.navigationItem = parent?.navigationItem
        filterBarController.configure(displayedTabs, in: self) { [weak self] in
            self?.selectedFilterDidChange($0)
        }
        filterBarController.accessibilityIdentifier = "site-stats-dashboard-filter-bar"
    }

    private func selectedFilterDidChange(_ item: StatsTabType) {
        currentSelectedTab = item
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
        let containerIsEmpty = currentChildViewController == nil
        let isGrowAudienceShowingOnInsights = insightsTableViewController.isGrowAudienceShowing

        switch currentSelectedTab {
        case .insights:
            if selectedPeriodChanged || containerIsEmpty || isGrowAudienceShowingOnInsights {
                showChildViewController(insightsTableViewController)
            } else {
                insightsTableViewController.refreshInsights()
            }
        case .traffic:
            if oldSelectedTab != .traffic || containerIsEmpty {
                showChildViewController(trafficTableViewController)
            } else {
                if let periodVC = trafficTableViewController as? SiteStatsPeriodTableViewController {
                    periodVC.refreshData()
                }
            }
        case .subscribers:
            if oldSelectedTab != .subscribers || containerIsEmpty {
                showChildViewController(subscribersViewController)
            } else {
                subscribersViewController.refreshData()
            }
        case .ads:
            if oldSelectedTab != .ads || containerIsEmpty {
                if let adsViewController {
                    showChildViewController(adsViewController)
                }
            }
        }
    }

    // MARK: - Container Management

    private func showChildViewController(_ childViewController: UIViewController) {
        // Remove current child if exists
        if let currentChild = currentChildViewController {
            _removeChildViewController(currentChild)
        }

        // Add new child
        _addChildViewController(childViewController)
        currentChildViewController = childViewController
    }

    private func _addChildViewController(_ child: UIViewController) {
        addChild(child)
        containerView.addSubview(child.view)

        // Configure constraints
        child.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            child.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            child.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        child.didMove(toParent: self)
    }

    private func _removeChildViewController(_ child: UIViewController) {
        child.willMove(toParent: nil)
        child.view.removeFromSuperview()
        child.removeFromParent()
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

// MARK: - Strings

private enum Strings {
    static let sendFeedback = NSLocalizedString(
        "stats.menu.sendFeedback",
        value: "Send Feedback",
        comment: "Menu item to send feedback about new stats experience"
    )

    static let switchToClassic = NSLocalizedString(
        "stats.menu.disableNewStats",
        value: "Disable New Stats",
        comment: "Menu item to disable the new stats"
    )

    static let tryNewStats = NSLocalizedString(
        "stats.menu.tryNewStats",
        value: "Try New Stats",
        comment: "Menu item to enable new stats experience"
    )
}
