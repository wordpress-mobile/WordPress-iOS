import UIKit
import WordPressFlux

enum InsightType: Int {
    case customize
    case latestPostSummary
    case allTimeStats
    case followersTotals
    case mostPopularTime
    case tagsAndCategories
    case annualSiteStats
    case comments
    case followers
    case todaysStats
    case postingActivity
    case publicize

    // TODO: remove when Manage Insights is implemented.
    static let allValues = [InsightType.latestPostSummary,
                            .todaysStats,
                            .annualSiteStats,
                            .allTimeStats,
                            .mostPopularTime,
                            .postingActivity,
                            .comments,
                            .tagsAndCategories,
                            .followersTotals,
                            .followers,
                            .publicize
    ]
}

@objc protocol SiteStatsInsightsDelegate {
    @objc optional func displayWebViewWithURL(_ url: URL)
    @objc optional func showCreatePost()
    @objc optional func showShareForPost(postID: NSNumber, fromView: UIView)
    @objc optional func showPostingActivityDetails()
    @objc optional func tabbedTotalsCellUpdated()
    @objc optional func expandedRowUpdated(_ row: StatsTotalRow, didSelectRow: Bool)
    @objc optional func viewMoreSelectedForStatSection(_ statSection: StatSection)
    @objc optional func showPostStats(postID: Int, postTitle: String?, postURL: URL?)
    @objc optional func customizeDismissButtonTapped()
    @objc optional func customizeTryButtonTapped()
    @objc optional func showAddInsight()
    @objc optional func addInsightSelected(_ insight: StatSection)

}

class SiteStatsInsightsTableViewController: UITableViewController, StoryboardLoadable {
    static var defaultStoryboardName: String = "SiteStatsDashboard"

    // MARK: - Properties
    private var insightsChangeReceipt: Receipt?

    // TODO: update this array when Manage Insights is implemented.
    // Types of Insights to display. The array order dictates the display order.
    private var insightsToShow = [InsightType]()
    private let userDefaultsInsightTypesKey = "StatsInsightTypes"

    // Store customize separately as it is not per site.
    // (insightsToShow is not yet per site, but it will be.)
    private let userDefaultsHideCustomizeKey = "StatsInsightsHideCustomizeCard"
    private var hideCustomizeCard = false
    private let asyncLoadingActivated = Feature.enabled(.statsAsyncLoading)

    private lazy var mainContext: NSManagedObjectContext = {
        return ContextManager.sharedInstance().mainContext
    }()

    private lazy var blogService: BlogService = {
        return BlogService(managedObjectContext: mainContext)
    }()

    private lazy var postService: PostService = {
        return PostService(managedObjectContext: mainContext)
    }()

    private var viewModel: SiteStatsInsightsViewModel?

    private let analyticsTracker = BottomScrollAnalyticsTracker()

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self, with: analyticsTracker)
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        clearExpandedRows()
        WPStyleGuide.Stats.configureTable(tableView)
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        loadInsightsFromUserDefaults()
        initViewModel()
        tableView.estimatedRowHeight = 500

        if !asyncLoadingActivated {
            displayLoadingViewIfNecessary()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        writeInsightsToUserDefaults()
    }

    func refreshInsights() {
        addViewModelListeners()
        viewModel?.refreshInsights()
    }
}

// MARK: - Private Extension

private extension SiteStatsInsightsTableViewController {

    func initViewModel() {
        viewModel = SiteStatsInsightsViewModel(insightsToShow: insightsToShow, insightsDelegate: self)
        addViewModelListeners()
        viewModel?.fetchInsights()
    }

    func addViewModelListeners() {
        if insightsChangeReceipt != nil {
            return
        }

        insightsChangeReceipt = viewModel?.onChange { [weak self] in
            let asyncLoadingActivated = self?.asyncLoadingActivated ?? false
            if !asyncLoadingActivated {
                if let viewModel = self?.viewModel,
                    viewModel.isFetchingOverview() {
                        return
                }
            }
            self?.refreshTableView()
        }
    }

    func removeViewModelListeners() {
        if asyncLoadingActivated {
            return
        }
        insightsChangeReceipt = nil
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [CellHeaderRow.self,
                CustomizeInsightsRow.self,
                LatestPostSummaryRow.self,
                TwoColumnStatsRow.self,
                PostingActivityRow.self,
                TabbedTotalsStatsRow.self,
                TopTotalsInsightStatsRow.self,
                TableFooterRow.self,
                StatsGhostTwoColumnImmutableRow.self]
    }

    // MARK: - Table Refreshing

    func refreshTableView() {
        guard let viewModel = viewModel else {
                return
        }

        if !asyncLoadingActivated {
            guard viewIsVisible() else {
                    return
            }
        }

        tableHandler.viewModel = viewModel.tableViewModel()

        if asyncLoadingActivated && viewModel.fetchingFailed() {
            displayFailureViewIfNecessary()
        } else {
            if viewModel.fetchingFailed() &&
                !viewModel.containsCachedData() {
                displayFailureViewIfNecessary()
            } else {
                hideNoResults()
            }
        }

        refreshControl?.endRefreshing()
    }

    @objc func refreshData() {
        refreshControl?.beginRefreshing()
        clearExpandedRows()
        refreshInsights()
    }

    func applyTableUpdates() {
        tableView.performBatchUpdates({
        })
    }

    func clearExpandedRows() {
        StatsDataHelper.clearExpandedInsights()
    }

    func viewIsVisible() -> Bool {
        return isViewLoaded && view.window != nil
    }

    // MARK: User Defaults

    func loadInsightsFromUserDefaults() {

        // TODO: remove when Manage Insights is implemented.
        // For now, we'll show all Insights in the default order.
        let allTypesInts = InsightType.allValues.map { $0.rawValue }

        let insightTypesInt = UserDefaults.standard.array(forKey: userDefaultsInsightTypesKey) as? [Int] ?? allTypesInts
        insightsToShow = insightTypesInt.compactMap { InsightType(rawValue: $0) }

        hideCustomizeCard = UserDefaults.standard.bool(forKey: userDefaultsHideCustomizeKey)

        if !hideCustomizeCard {
            // Insert customize at the beginning of the array so it is displayed first.
            insightsToShow.insert(.customize, at: 0)
        }
    }

    func writeInsightsToUserDefaults() {
        // Remove customize from array since it is not per site.
        // (insightsToShow is not yet per site, but it will be.)
        insightsToShow = insightsToShow.filter { $0 != .customize }

        let insightTypesInt = insightsToShow.compactMap { $0.rawValue }
        UserDefaults.standard.set(insightTypesInt, forKey: userDefaultsInsightTypesKey)

        UserDefaults.standard.set(hideCustomizeCard, forKey: userDefaultsHideCustomizeKey)
    }

    // MARK: - Insights Management

    func showAddInsightView() {
        let controller = AddInsightTableViewController()
        controller.insightsDelegate = self
        navigationController?.pushViewController(controller, animated: true)
    }

}

extension SiteStatsInsightsTableViewController: NoResultsViewHost {
    private func displayLoadingViewIfNecessary() {
        guard tableHandler.viewModel.sections.isEmpty else {
            return
        }

        configureAndDisplayNoResults(on: tableView,
                                     title: NoResultConstants.successTitle,
                                     accessoryView: NoResultsViewController.loadingAccessoryView()) { [weak self] noResults in
                                        noResults.delegate = self
                                        noResults.hideImageView(false)
        }
    }

    private func displayFailureViewIfNecessary() {
        guard tableHandler.viewModel.sections.isEmpty else {
            return
        }

        if asyncLoadingActivated {
            configureAndDisplayNoResults(on: tableView,
                                         title: NoResultConstants.errorTitle,
                                         subtitle: NoResultConstants.errorSubtitle,
                                         buttonTitle: NoResultConstants.refreshButtonTitle) { [weak self] noResults in
                                            noResults.delegate = self
            }
        } else {
            updateNoResults(title: NoResultConstants.errorTitle,
                            subtitle: NoResultConstants.errorSubtitle,
                            buttonTitle: NoResultConstants.refreshButtonTitle) { [weak self] noResults in
                                noResults.delegate = self
                                noResults.hideImageView()
            }
        }
    }

    private enum NoResultConstants {
        static let successTitle = NSLocalizedString("Loading Stats...", comment: "The loading view title displayed while the service is loading")
        static let errorTitle = NSLocalizedString("Stats not loaded", comment: "The loading view title displayed when an error occurred")
        static let errorSubtitle = NSLocalizedString("There was a problem loading your data, refresh your page to try again.", comment: "The loading view subtitle displayed when an error occurred")
        static let refreshButtonTitle = NSLocalizedString("Refresh", comment: "The loading view button title displayed when an error occurred")
    }
}

// MARK: - SiteStatsInsightsDelegate Methods

extension SiteStatsInsightsTableViewController: SiteStatsInsightsDelegate {

    func displayWebViewWithURL(_ url: URL) {
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url)
        let navController = UINavigationController.init(rootViewController: webViewController)
        present(navController, animated: true)
    }

    func showCreatePost() {
        WPTabBarController.sharedInstance().showPostTab { [weak self] in
            self?.refreshInsights()
        }
    }

    func showShareForPost(postID: NSNumber, fromView: UIView) {
        guard let blogId = SiteStatsInformation.sharedInstance.siteID,
        let blog = blogService.blog(byBlogId: blogId) else {
            DDLogInfo("Failed to get blog with id \(String(describing: SiteStatsInformation.sharedInstance.siteID))")
            return
        }

        postService.getPostWithID(postID, for: blog, success: { apost in
            guard let post = apost as? Post else {
                DDLogInfo("Failed to get post with id \(postID)")
                return
            }

            let shareController = PostSharingController()
            shareController.sharePost(post, fromView: fromView, inViewController: self)
        }, failure: { error in
            DDLogInfo("Error getting post with id \(postID): \(error.localizedDescription)")
        })
    }

    func showPostingActivityDetails() {
        guard let viewModel = viewModel else {
            return
        }

        let postingActivityViewController = PostingActivityViewController.loadFromStoryboard()
        postingActivityViewController.yearData = viewModel.yearlyPostingActivity()
        navigationController?.pushViewController(postingActivityViewController, animated: true)
    }

    func tabbedTotalsCellUpdated() {
        applyTableUpdates()
    }

    func expandedRowUpdated(_ row: StatsTotalRow, didSelectRow: Bool) {
        if didSelectRow {
            applyTableUpdates()
        }
        StatsDataHelper.updatedExpandedState(forRow: row)
    }

    func viewMoreSelectedForStatSection(_ statSection: StatSection) {
        guard StatSection.allInsights.contains(statSection) else {
            return
        }

        removeViewModelListeners()

        // When displaying Annual details, start from the most recent year available.
        var selectedDate: Date?
        if statSection == .insightsAnnualSiteStats,
            let year = viewModel?.annualInsightsYear() {
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: StatsDataHelper.currentDateForSite())
            dateComponents.year = year
            selectedDate = Calendar.current.date(from: dateComponents)
        }

        let detailTableViewController = SiteStatsDetailTableViewController.loadFromStoryboard()
        detailTableViewController.configure(statSection: statSection, selectedDate: selectedDate)
        navigationController?.pushViewController(detailTableViewController, animated: true)
    }

    func showPostStats(postID: Int, postTitle: String?, postURL: URL?) {
        removeViewModelListeners()

        let postStatsTableViewController = PostStatsTableViewController.loadFromStoryboard()
        postStatsTableViewController.configure(postID: postID, postTitle: postTitle, postURL: postURL)
        navigationController?.pushViewController(postStatsTableViewController, animated: true)
    }

    func customizeDismissButtonTapped() {
        hideCustomizeCard = true
        insightsToShow = insightsToShow.filter { $0 != .customize }
        viewModel?.updateInsightsToShow(insights: insightsToShow)
        refreshTableView()
        writeInsightsToUserDefaults()
    }

    func customizeTryButtonTapped() {
        showAddInsightView()
    }

    func showAddInsight() {
        showAddInsightView()
    }

    func addInsightSelected(_ insight: StatSection) {
        NSLog("Add Insight selected: \(insight.insightManagementTitle)")
    }

}

extension SiteStatsInsightsTableViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        if asyncLoadingActivated {
            hideNoResults()
        } else {
            updateNoResults(title: NoResultConstants.successTitle,
                            accessoryView: NoResultsViewController.loadingAccessoryView()) { noResults in
                                noResults.hideImageView(false)
            }
        }
        addViewModelListeners()
        refreshInsights()
    }
}
