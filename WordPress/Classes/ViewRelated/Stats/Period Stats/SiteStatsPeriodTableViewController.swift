import UIKit
import WordPressFlux

enum PeriodDisplayed: Int {
    case days = 1
    case weeks
    case months
    case years
}

class SiteStatsPeriodTableViewController: UITableViewController {

    // MARK: - Properties

    var periodDisplayed: PeriodDisplayed? = .days {
        didSet {
            DDLogInfo("Stats Period selected: \(String(describing: periodDisplayed))")
            guard periodDisplayed != nil else {
                return
            }
            refreshData()
        }
    }

    private let store = StoreContainer.shared.statsPeriod
    private var changeReceipt: Receipt?

    private var viewModel: SiteStatsPeriodViewModel?

    private lazy var tableHandler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.Stats.configureTable(tableView)
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        ImmuTable.registerRows(tableRowTypes(), tableView: tableView)
        initViewModel()
    }

}

// MARK: - Private Extension

private extension SiteStatsPeriodTableViewController {

    // MARK: - View Model

    func initViewModel() {
        viewModel = SiteStatsPeriodViewModel(store: store)

        // TODO: remove this when code below is utilized.
        refreshTableView()

        // TODO: uncomment this when the Store actually does something.

//        changeReceipt = viewModel?.onChange { [weak self] in
//            guard let store = self?.store,
//                !store.isFetching else {
//                    return
//            }
//
//            self?.refreshTableView()
//        }
    }

    func tableRowTypes() -> [ImmuTableRow.Type] {
        return [CellHeaderRow.self, TopTotalsStatsRow.self]
    }

    // MARK: - Table Refreshing

    func refreshTableView() {
        guard let viewModel = viewModel else {
            return
        }

        tableHandler.viewModel = viewModel.tableViewModel()
//        refreshControl?.endRefreshing()
    }

    @objc func refreshData() {
//        refreshControl?.beginRefreshing()

        // TODO: use PeriodDisplayed when fetching data
        viewModel?.refreshPeriodData()
    }

}
