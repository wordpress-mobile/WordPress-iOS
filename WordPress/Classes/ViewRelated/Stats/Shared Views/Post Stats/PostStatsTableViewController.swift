import UIKit

class PostStatsTableViewController: UITableViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = defaultControllerID

    // MARK: - Properties

    private typealias Style = WPStyleGuide.Stats
    private var viewModel: PostStatsViewModel?

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Stats", comment: "Window title for Post Stats view.")
        Style.configureTable(tableView)
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        initViewModel()
    }

}

// MARK: - Table Methods

private extension PostStatsTableViewController {

    func initViewModel() {
        viewModel = PostStatsViewModel()
        refreshTableView()
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [CellHeaderRow.self,
                PostStatsTitleRow.self,
                TableFooterRow.self]
    }

    // MARK: - Table Refreshing

    func refreshTableView() {
        guard let viewModel = viewModel else {
            return
        }

        tableHandler.viewModel = viewModel.tableViewModel()
    }

}
