import UIKit

@objc protocol PostStatsDelegate {
    @objc optional func displayWebViewWithURL(_ url: URL)
}

class PostStatsTableViewController: UITableViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = defaultControllerID

    // MARK: - Properties

    private var postTitle: String?
    private var postURL: URL?
    private typealias Style = WPStyleGuide.Stats
    private var viewModel: PostStatsViewModel?

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Stats", comment: "Window title for Post Stats view.")
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        Style.configureTable(tableView)
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        initViewModel()
    }

    func configure(postTitle: String?, postURL: URL?) {
        self.postTitle = postTitle
        self.postURL = postURL
    }
}

// MARK: - Table Methods

private extension PostStatsTableViewController {

    func initViewModel() {
        viewModel = PostStatsViewModel(postTitle: postTitle, postURL: postURL, postStatsDelegate: self)
        refreshTableView()
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [CellHeaderRow.self,
                PostStatsTitleRow.self,
                OverviewRow.self,
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

        // TODO: data fetching

        refreshControl?.endRefreshing()
    }

}

// MARK: - PostStatsDelegate Methods

extension PostStatsTableViewController: PostStatsDelegate {

    func displayWebViewWithURL(_ url: URL) {
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url)
        let navController = UINavigationController.init(rootViewController: webViewController)
        present(navController, animated: true)
    }

}
