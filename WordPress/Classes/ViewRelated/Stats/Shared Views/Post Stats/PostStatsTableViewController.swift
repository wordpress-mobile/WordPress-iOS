import UIKit
import WordPressFlux

@objc protocol PostStatsDelegate {
    @objc optional func displayWebViewWithURL(_ url: URL)
    @objc optional func expandedRowUpdated(_ row: StatsTotalRow)
}

class PostStatsTableViewController: UITableViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = defaultControllerID

    // MARK: - Properties

    private var postTitle: String?
    private var postURL: URL?
    private var postID: Int?
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
        initViewModel()
    }

    func configure(postID: Int, postTitle: String?, postURL: URL?) {
        self.postID = postID
        self.postTitle = postTitle
        self.postURL = postURL
    }
}

// MARK: - Table Methods

private extension PostStatsTableViewController {

    func initViewModel() {

        guard let postID = postID else {
            return
        }

        viewModel = PostStatsViewModel(postID: postID, postTitle: postTitle, postURL: postURL, postStatsDelegate: self)

        changeReceipt = viewModel?.onChange { [weak self] in
            guard let store = self?.store,
                !store.isFetchingPostStats else {
                    return
            }

            self?.refreshTableView()
        }
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [CellHeaderRow.self,
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

        viewModel?.refreshPostStats(postID: postID)
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


}
