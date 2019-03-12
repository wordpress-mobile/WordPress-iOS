import UIKit
import WordPressFlux

@objc protocol SiteStatsDetailsDelegate {
    @objc optional func tabbedTotalsCellUpdated()
    @objc optional func displayWebViewWithURL(_ url: URL)
    @objc optional func expandedRowUpdated(_ row: StatsTotalRow)
    @objc optional func showPostStats(withPostTitle postTitle: String?)
}

class SiteStatsDetailTableViewController: UITableViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = defaultControllerID

    // MARK: - Properties

    private typealias Style = WPStyleGuide.Stats
    private var statSection: StatSection?
    private var statType: StatType = .period
    private var selectedDate: Date?
    private var selectedPeriod: StatsPeriodUnit?

    private var viewModel: SiteStatsDetailsViewModel?
    private let insightsStore = StoreContainer.shared.statsInsights
    private var insightsChangeReceipt: Receipt?
    private let periodStore = StoreContainer.shared.statsPeriod
    private var periodChangeReceipt: Receipt?

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        Style.configureTable(tableView)
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
    }

    func configure(statSection: StatSection, selectedDate: Date? = nil, selectedPeriod: StatsPeriodUnit? = nil) {
        self.statSection = statSection
        self.selectedDate = selectedDate
        self.selectedPeriod = selectedPeriod
        statType = StatSection.allInsights.contains(statSection) ? .insights : .period
        title = statSection.title
        initViewModel()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // This is primarily to resize the NoResultsView in a TabbedTotalsCell on rotation.
        coordinator.animate(alongsideTransition: { _ in
            self.tableView.reloadData()
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard let statSection = statSection else {
            return
        }
        StatsDataHelper.clearExpandedRowsFor(statSection: statSection)
    }


}

// MARK: - Table Methods

private extension SiteStatsDetailTableViewController {

    func initViewModel() {
        viewModel = SiteStatsDetailsViewModel(detailsDelegate: self)

        guard let statSection = statSection else {
            return
        }

        viewModel?.fetchDataFor(statSection: statSection, selectedDate: selectedDate, selectedPeriod: selectedPeriod)

        if statType == .insights {
            insightsChangeReceipt = viewModel?.onChange { [weak self] in
                guard self?.storeIsFetching(statSection: statSection) == false else {
                    return
                }
                self?.refreshTableView()
            }
        } else {
            periodChangeReceipt = viewModel?.onChange { [weak self] in
                guard self?.storeIsFetching(statSection: statSection) == false else {
                    return
                }
                self?.refreshTableView()
            }
        }
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [TabbedTotalsDetailStatsRow.self,
                TopTotalsDetailStatsRow.self,
                TableFooterRow.self]
    }

    func storeIsFetching(statSection: StatSection) -> Bool {
        switch statSection {
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            return insightsStore.isFetchingFollowers
        case .insightsCommentsAuthors, .insightsCommentsPosts:
            return insightsStore.isFetchingComments
        case .insightsTagsAndCategories:
            return insightsStore.isFetchingTagsAndCategories
        case .periodPostsAndPages:
            return periodStore.isFetchingPostsAndPages
        default:
            return false
        }
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
        guard let statSection = statSection else {
            return
        }

        refreshControl?.beginRefreshing()

        switch statSection {
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            viewModel?.refreshFollowers()
        case .insightsCommentsAuthors, .insightsCommentsPosts:
            viewModel?.refreshComments()
        case .insightsTagsAndCategories:
            viewModel?.refreshTagsAndCategories()
        default:
            refreshControl?.endRefreshing()
        }

    }

    func applyTableUpdates() {
        if #available(iOS 11.0, *) {
            tableView.performBatchUpdates({
                updateStatSectionForFilterChange()
            })
        } else {
            tableView.beginUpdates()
            updateStatSectionForFilterChange()
            tableView.endUpdates()
        }
    }

    func updateStatSectionForFilterChange() {
        guard let oldStatSection = statSection else {
            return
        }

        switch oldStatSection {
        case .insightsFollowersWordPress:
            statSection = .insightsFollowersEmail
        case .insightsFollowersEmail:
            statSection = .insightsFollowersWordPress
        case .insightsCommentsAuthors:
            statSection = .insightsCommentsPosts
        case .insightsCommentsPosts:
            statSection = .insightsCommentsAuthors
        default:
            // Return here as `initViewModel` is only needed for filtered cards.
            return
        }

        initViewModel()
    }

}

// MARK: - SiteStatsDetailsDelegate Methods

extension SiteStatsDetailTableViewController: SiteStatsDetailsDelegate {

    func tabbedTotalsCellUpdated() {
        applyTableUpdates()
    }

    func displayWebViewWithURL(_ url: URL) {
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url)
        let navController = UINavigationController.init(rootViewController: webViewController)
        present(navController, animated: true, completion: nil)
    }

    func expandedRowUpdated(_ row: StatsTotalRow) {
        applyTableUpdates()
        StatsDataHelper.updatedExpandedState(forRow: row)
    }

    func showPostStats(withPostTitle postTitle: String?) {
        let postStatsTableViewController = PostStatsTableViewController.loadFromStoryboard()
        postStatsTableViewController.configure(postTitle: postTitle)
        navigationController?.pushViewController(postStatsTableViewController, animated: true)
    }

}
