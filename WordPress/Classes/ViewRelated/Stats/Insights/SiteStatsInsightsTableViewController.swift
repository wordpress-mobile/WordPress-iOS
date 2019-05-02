import UIKit
import WordPressFlux

enum InsightType: Int {
    case latestPostSummary
    case allTimeStats
    case followersTotals
    case mostPopularDayAndHour
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
                            .mostPopularDayAndHour,
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
    @objc optional func expandedRowUpdated(_ row: StatsTotalRow)
    @objc optional func viewMoreSelectedForStatSection(_ statSection: StatSection)
    @objc optional func showPostStats(postID: Int, postTitle: String?, postURL: URL?)
}

class SiteStatsInsightsTableViewController: UITableViewController, NoResultsViewHost {

    // MARK: - Properties

    private let store = StoreContainer.shared.statsInsights
    private var changeReceipt: Receipt?

    // TODO: update this array when Manage Insights is implemented.
    // Types of Insights to display. The array order dictates the display order.
    private var insightsToShow = [InsightType]()
    private let userDefaultsKey = "StatsInsightTypes"

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

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
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
        displayLoadingViewIfNecessary()
        tableView.estimatedRowHeight = 500
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        writeInsightsToUserDefaults()
    }
}

// MARK: - Private Extension

private extension SiteStatsInsightsTableViewController {

    func initViewModel() {
        viewModel = SiteStatsInsightsViewModel(insightsToShow: insightsToShow, insightsDelegate: self, store: store)

        changeReceipt = viewModel?.onChange { [weak self] in
            guard let store = self?.store,
                !store.isFetchingOverview else {
                return
            }
            self?.refreshTableView()
        }
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [CellHeaderRow.self,
                LatestPostSummaryRow.self,
                SimpleTotalsStatsRow.self,
                SimpleTotalsStatsSubtitlesRow.self,
                PostingActivityRow.self,
                TabbedTotalsStatsRow.self,
                TopTotalsInsightStatsRow.self,
                AnnualSiteStatsRow.self,
                TableFooterRow.self]
    }

    func displayLoadingViewIfNecessary() {
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

    func displayFailureViewIfNecessary() {
        guard tableHandler.viewModel.sections.isEmpty else {
            return
        }

        let customizationBlock: NoResultsCustomizationBlock = { [weak self] noResults in
            noResults.delegate = self
            noResults.hideImageView()
        }

        if noResultsViewController.view.superview != nil {
            updateNoResults(title: NoResultConstants.errorTitle,
                            subtitle: NoResultConstants.errorSubtitle,
                            buttonTitle: NoResultConstants.refreshButtonTitle,
                            customizationBlock: customizationBlock)
        } else {
            configureAndDisplayNoResults(on: tableView,
                                         title: NoResultConstants.errorTitle,
                                         subtitle: NoResultConstants.errorSubtitle,
                                         buttonTitle: NoResultConstants.refreshButtonTitle,
                                         customizationBlock: customizationBlock)
        }
    }

    // MARK: - Table Refreshing

    func refreshTableView() {

        guard let viewModel = viewModel,
            viewIsVisible() else {
                return
        }

        tableHandler.viewModel = viewModel.tableViewModel()

        if store.fetchingOverviewHasFailed {
            displayFailureViewIfNecessary()
        } else {
            hideNoResults()
        }

        refreshControl?.endRefreshing()
    }

    @objc func refreshData() {
        refreshControl?.beginRefreshing()
        clearExpandedRows()
        viewModel?.refreshInsights()
    }

    func applyTableUpdates() {
        if #available(iOS 11.0, *) {
            tableView.performBatchUpdates({
            })
        } else {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
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

        let insightTypesInt = UserDefaults.standard.array(forKey: userDefaultsKey) as? [Int] ?? allTypesInts
        insightsToShow = insightTypesInt.compactMap { InsightType(rawValue: $0) }
    }

    func writeInsightsToUserDefaults() {
        let insightTypesInt = insightsToShow.compactMap { $0.rawValue }
        UserDefaults.standard.set(insightTypesInt, forKey: userDefaultsKey)
    }

    enum NoResultConstants {
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
            self?.viewModel?.refreshInsights()
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
        let postingActivityViewController = PostingActivityViewController.loadFromStoryboard()
        postingActivityViewController.yearData = store.getYearlyPostingActivityFrom(date: Date())
        navigationController?.pushViewController(postingActivityViewController, animated: true)
    }

    func tabbedTotalsCellUpdated() {
        applyTableUpdates()
    }

    func expandedRowUpdated(_ row: StatsTotalRow) {
        applyTableUpdates()
        StatsDataHelper.updatedExpandedState(forRow: row)
    }

    func viewMoreSelectedForStatSection(_ statSection: StatSection) {
        guard StatSection.allInsights.contains(statSection) else {
            return
        }

        let detailTableViewController = SiteStatsDetailTableViewController.loadFromStoryboard()
        detailTableViewController.configure(statSection: statSection)
        navigationController?.pushViewController(detailTableViewController, animated: true)
    }

    func showPostStats(postID: Int, postTitle: String?, postURL: URL?) {
        let postStatsTableViewController = PostStatsTableViewController.loadFromStoryboard()
        postStatsTableViewController.configure(postID: postID, postTitle: postTitle, postURL: postURL)
        navigationController?.pushViewController(postStatsTableViewController, animated: true)
    }

}

extension SiteStatsInsightsTableViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        updateNoResults(title: NoResultConstants.successTitle,
                        accessoryView: NoResultsViewController.loadingAccessoryView()) { noResults in
                            noResults.hideImageView(false)
        }
        viewModel?.refreshInsights()
    }
}
