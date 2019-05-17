import UIKit
import WordPressFlux

@objc protocol PostStatsDelegate {
    @objc optional func displayWebViewWithURL(_ url: URL)
    @objc optional func expandedRowUpdated(_ row: StatsTotalRow)
    @objc optional func viewMoreSelectedForStatSection(_ statSection: StatSection)
}

class PostStatsTableViewController: UITableViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = defaultControllerID

    // MARK: - Properties

    private var postTitle: String?
    private var postURL: URL?
    private var postID: Int?
    private var selectedDate = Date()
    private typealias Style = WPStyleGuide.Stats
    private var viewModel: PostStatsViewModel?
    private let store = StoreContainer.shared.statsPeriod
    private var changeReceipt: Receipt?

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Stats", comment: "Window title for Post Stats view.")
        refreshControl?.addTarget(self, action: #selector(userInitiatedRefresh), for: .valueChanged)
        Style.configureTable(tableView)
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        tableView.register(SiteStatsTableHeaderView.defaultNib,
                           forHeaderFooterViewReuseIdentifier: SiteStatsTableHeaderView.defaultNibName)
        initViewModel()
    }

    func configure(postID: Int, postTitle: String?, postURL: URL?) {
        self.postID = postID
        self.postTitle = postTitle
        self.postURL = postURL
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: SiteStatsTableHeaderView.defaultNibName) as? SiteStatsTableHeaderView else {
            return nil
        }

        cell.configure(date: selectedDate, period: .day, delegate: self)
        viewModel?.statsBarChartViewDelegate = cell

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return SiteStatsTableHeaderView.height
    }

}

// MARK: - Table Methods

private extension PostStatsTableViewController {

    func initViewModel() {

        guard let postID = postID else {
            return
        }

        viewModel = PostStatsViewModel(postID: postID,
                                       selectedDate: selectedDate,
                                       postTitle: postTitle,
                                       postURL: postURL,
                                       postStatsDelegate: self)

        changeReceipt = viewModel?.onChange { [weak self] in
            guard let store = self?.store,
                !store.isFetchingPostStats else {
                    return
            }

            self?.refreshTableView()
        }
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [PostStatsEmptyCellHeaderRow.self,
                CellHeaderRow.self,
                PostStatsTitleRow.self,
                OverviewRow.self,
                TopTotalsPostStatsRow.self,
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

    @objc func userInitiatedRefresh() {
        refreshControl?.beginRefreshing()
        refreshData()
    }

    func refreshData() {
        guard let postID = postID else {
            return
        }

        viewModel?.refreshPostStats(postID: postID, selectedDate: selectedDate)
    }

    func applyTableUpdates() {
        tableView.performBatchUpdates({
        })
    }

}

// MARK: - PostStatsDelegate Methods

extension PostStatsTableViewController: PostStatsDelegate {

    func displayWebViewWithURL(_ url: URL) {
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url)
        let navController = UINavigationController.init(rootViewController: webViewController)
        present(navController, animated: true)
    }

    func expandedRowUpdated(_ row: StatsTotalRow) {
        applyTableUpdates()
    }

    func viewMoreSelectedForStatSection(_ statSection: StatSection) {
        guard StatSection.allPostStats.contains(statSection) else {
            return
        }

        let detailTableViewController = SiteStatsDetailTableViewController.loadFromStoryboard()
        detailTableViewController.configure(statSection: statSection, postID: postID)
        navigationController?.pushViewController(detailTableViewController, animated: true)
    }

}

// MARK: - SiteStatsTableHeaderDelegate Methods

extension PostStatsTableViewController: SiteStatsTableHeaderDelegate {

    func dateChangedTo(_ newDate: Date?) {
        guard let newDate = newDate else {
            return
        }

        selectedDate = newDate
        refreshData()
    }

}
