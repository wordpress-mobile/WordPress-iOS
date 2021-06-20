import UIKit

final class ReferrerDetailsTableViewController: UITableViewController {
    private lazy var tableHandler = ImmuTableViewHandler(takeOver: self)
    private let viewModel = ReferrerDetailsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        buildViewModel()
    }
}

// MARK: - UITableViewDelegate
extension ReferrerDetailsTableViewController {
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .zero
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .zero
    }
}

// MARK: - Private Methods
private extension ReferrerDetailsTableViewController {
    func setupViews() {
        tableView.backgroundColor = WPStyleGuide.Stats.tableBackgroundColor
        tableView.tableFooterView = UIView()
        ImmuTable.registerRows(rows, tableView: tableView)
    }

    func buildViewModel() {
        tableHandler.viewModel = viewModel.tableViewModel
    }
}

// MARK: - Private Computed Properties
private extension ReferrerDetailsTableViewController {
    var rows: [ImmuTableRow.Type] {
        [ReferrerDetailsHeaderRow.self,
         ReferrerDetailsRow.self,
         ReferrerDetailsSpamActionRow.self]
    }
}
