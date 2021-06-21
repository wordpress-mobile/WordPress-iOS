import UIKit

final class ReferrerDetailsTableViewController: UITableViewController {
    private let data: StatsTotalRowData
    private lazy var tableHandler = ImmuTableViewHandler(takeOver: self)
    private lazy var viewModel = ReferrerDetailsViewModel(data: data, delegate: self)
    private let periodStore = StoreContainer.shared.statsPeriod

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
        showSpamActionSheet(for: referrerDomain, isSpam: currentValue) { [weak self] in
            self?.periodStore.toggleSpamState(for: referrerDomain, currentValue: currentValue)
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

    func showSpamActionSheet(for referrerDomain: String, isSpam: Bool, action: @escaping () -> Void) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let markTitle = NSLocalizedString("Mark as spam", comment: "Action title for marking referrer as spam")
        let unmarkTitle = NSLocalizedString("Unmark as spam", comment: "Action title for unmarking referrer as spam")

        let title = isSpam ? unmarkTitle : markTitle
        let toggleSpamAction = UIAlertAction(title: title, style: .default) { _ in
            action()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        [toggleSpamAction, cancelAction].forEach {
            sheet.addAction($0)
        }
        present(sheet, animated: true)
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
