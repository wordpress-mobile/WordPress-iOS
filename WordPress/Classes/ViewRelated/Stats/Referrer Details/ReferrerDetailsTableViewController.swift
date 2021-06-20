import UIKit

final class ReferrerDetailsTableViewController: UITableViewController {
    private lazy var tableHandler = ImmuTableViewHandler(takeOver: self)
    private let viewModel = ReferrerDetailsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.Stats.configureTable(tableView)
        ImmuTable.registerRows(rows, tableView: tableView)
        buildViewModel()
    }
}

// MARK: - Private Methods
private extension ReferrerDetailsTableViewController {
    func buildViewModel() {
        tableHandler.viewModel = viewModel.tableViewModel
    }
}

// MARK: - Private Computed Properties
private extension ReferrerDetailsTableViewController {
    var rows: [ImmuTableRow.Type] {
        [ReferrerDetailsHeaderRow.self]
    }
}
