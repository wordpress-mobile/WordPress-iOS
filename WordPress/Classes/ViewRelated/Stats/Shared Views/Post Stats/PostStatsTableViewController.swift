import UIKit

class PostStatsTableViewController: UITableViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = defaultControllerID

    // MARK: - Properties

    private var postTitle: String?
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

    func configure(postTitle: String?) {
        self.postTitle = postTitle
    }
}

// MARK: - Table Methods

private extension PostStatsTableViewController {

    func initViewModel() {
        viewModel = PostStatsViewModel(postTitle: postTitle)
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
