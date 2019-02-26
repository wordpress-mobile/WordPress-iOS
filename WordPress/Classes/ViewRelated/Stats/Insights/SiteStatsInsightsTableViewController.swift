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
}

class SiteStatsInsightsTableViewController: UITableViewController {

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

    // MARK: - Table Refreshing

    func refreshTableView() {
        guard let viewModel = viewModel else {
            return
        }

        tableHandler.viewModel = viewModel.tableViewModel()
        refreshControl?.endRefreshing()
    }

    @objc func refreshData() {
        refreshControl?.beginRefreshing()
        clearExpandedRows()
        viewModel?.refreshInsights()
    }

    func applyTableUpdates() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    func clearExpandedRows() {
        StatsDataHelper.clearExpandedInsights()
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

}

// MARK: - SiteStatsInsightsDelegate Methods

extension SiteStatsInsightsTableViewController: SiteStatsInsightsDelegate {

    func displayWebViewWithURL(_ url: URL) {
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url)
        let navController = UINavigationController.init(rootViewController: webViewController)
        present(navController, animated: true, completion: nil)
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
        detailTableViewController.configure(statSection: statSection, siteStatsInsightsDelegate: self)
        navigationController?.pushViewController(detailTableViewController, animated: true)
    }

}
