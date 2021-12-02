import UIKit

final class ReferrerDetailsTableViewController: UITableViewController {
    private var data: StatsTotalRowData
    private lazy var tableHandler = ImmuTableViewHandler(takeOver: self)
    private lazy var viewModel = ReferrerDetailsViewModel(data: data, delegate: self)
    private let periodStore = StoreContainer.shared.statsPeriod

    init(data: StatsTotalRowData) {
        self.data = data
        super.init(style: .plain)
        periodStore.delegate = self
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
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url, source: "stats_referrer_details")
        let navController = UINavigationController(rootViewController: webViewController)
        present(navController, animated: true)
    }

    func toggleSpamState(for referrerDomain: String, currentValue: Bool) {
        setLoadingState(true)
        periodStore.toggleSpamState(for: referrerDomain, currentValue: currentValue)
    }
}

// MARK: - StatsPeriodStoreDelegate
extension ReferrerDetailsTableViewController: StatsPeriodStoreDelegate {
    func didChangeSpamState(for referrerDomain: String, isSpam: Bool) {
        setLoadingState(false)
        data.isReferrerSpam = isSpam
        updateViewModel()

        let markedText = NSLocalizedString("marked as spam", comment: "Indicating that referrer was marked as spam")
        let unmarkedText = NSLocalizedString("unmarked as spam", comment: "Indicating that referrer was unmarked as spam")
        let text = isSpam ? markedText : unmarkedText
        displayNotice(title: "\(referrerDomain) \(text)")
    }

    func changingSpamStateForReferrerDomainFailed(oldValue: Bool) {
        setLoadingState(false)

        let markText = NSLocalizedString("Couldn't mark as spam", comment: "Indicating that referrer couldn't be marked as spam")
        let unmarkText = NSLocalizedString("Couldn't unmark as spam", comment: "Indicating that referrer couldn't be unmarked as spam")
        let text = oldValue ? unmarkText : markText
        displayNotice(title: text)
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

    func updateViewModel() {
        viewModel.update(with: data)
        buildViewModel()
    }

    func setLoadingState(_ value: Bool) {
        viewModel.setLoadingState(value)
        buildViewModel()
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
