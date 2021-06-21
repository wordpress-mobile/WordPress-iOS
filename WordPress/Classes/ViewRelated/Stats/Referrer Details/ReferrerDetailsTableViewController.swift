import UIKit

final class ReferrerDetailsTableViewController: UITableViewController {
    private lazy var tableHandler = ImmuTableViewHandler(takeOver: self)
    private let viewModel: ReferrerDetailsViewModel

    init(data: StatsTotalRowData) {
        self.viewModel = ReferrerDetailsViewModel(data: data)
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        switch section {
        case tableView.numberOfSections - 1:
            return .zero
        default:
            return UITableView.automaticDimension
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch section {
        case tableView.numberOfSections - 1:
            return nil
        default:
            return UIView()
        }
    }
}

// MARK: - Private Methods
private extension ReferrerDetailsTableViewController {
    func setupViews() {
        tableView.backgroundColor = WPStyleGuide.Stats.tableBackgroundColor
        tableView.tableFooterView = UIView()
        title = viewModel.title
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
