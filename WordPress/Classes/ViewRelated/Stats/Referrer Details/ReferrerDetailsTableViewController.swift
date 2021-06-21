import UIKit

final class ReferrerDetailsTableViewController: UITableViewController {
    private let data: StatsTotalRowData
    private lazy var tableHandler = ImmuTableViewHandler(takeOver: self)
    private lazy var viewModel = ReferrerDetailsViewModel(data: data, delegate: self)

    init(data: StatsTotalRowData) {
        self.data = data
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

// MARK: - ReferrerDetailsViewModelDelegate
extension ReferrerDetailsTableViewController: ReferrerDetailsViewModelDelegate {
    func displayWebViewWithURL(_ url: URL) {
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url)
        let navController = UINavigationController(rootViewController: webViewController)
        present(navController, animated: true)
    }

    func toggleSpamState(for referrerDomain: String, currentValue: Bool) {
        // TODO: implement
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
