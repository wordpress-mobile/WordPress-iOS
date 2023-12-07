import UIKit
import Combine
import AutomatticTracks

final class AllDomainsListViewController: UIViewController {

    // MARK: - Types

    enum Constants {
        static let analyticsSource = "all_domains"
    }

    private enum Layout {
        static let interRowSpacing = Length.Padding.double
    }

    private enum CellIdentifiers {
        static let myDomain = String(describing: AllDomainsListTableViewCell.self)
        static let activityIndicator = String(describing: AllDomainsListActivityIndicatorTableViewCell.self)
    }

    typealias ViewModel = AllDomainsListViewModel
    typealias Domain = AllDomainsListItemViewModel

    // MARK: - Dependencies

    private let crashLogger: CrashLogging
    private let viewModel: ViewModel

    // MARK: - Views

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let refreshControl = UIRefreshControl()
    private let emptyView = AllDomainsListEmptyView()

    // MARK: - Properties

    private lazy var state: ViewModel.State = viewModel.state

    // MARK: - Observation

    private var cancellable = Set<AnyCancellable>()

    // MARK: - Init

    init(viewModel: ViewModel = .init(), crashLogger: CrashLogging = CrashLogging.main) {
        self.viewModel = viewModel
        self.crashLogger = crashLogger
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public Functions

    func reloadDomains() {
        viewModel.loadData()
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.addDomainAction = { [weak self] in
            self?.navigateToAddDomain()
            WPAnalytics.track(.addDomainTapped)
        }
        self.title = Strings.title
        WPStyleGuide.configureColors(view: view, tableView: nil)
        self.setupSubviews()
        self.observeState()
        self.viewModel.loadData()
        WPAnalytics.track(.domainsListShown)
    }

    // MARK: - Setup Views

    private func setupSubviews() {
        self.setupBarButtonItems()
        self.setupSearchBar()
        self.setupTableView()
        self.setupRefreshControl()
        self.setupEmptyView()
        self.setupNavigationBarAppearance()
    }

    private func setupBarButtonItems() {
        let addAction = UIAction { [weak self] _ in
            self?.viewModel.addDomainAction?()
        }
        let addBarButtonItem = UIBarButtonItem(systemItem: .add, primaryAction: addAction)
        self.navigationItem.rightBarButtonItem = addBarButtonItem
    }

    private func setupSearchBar() {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = Strings.searchBar
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.extendedLayoutIncludesOpaqueBars = true
        self.edgesForExtendedLayout = .top
    }

    private func setupTableView() {
        self.tableView.backgroundColor = UIColor.systemGroupedBackground
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.sectionHeaderHeight = .leastNormalMagnitude
        self.tableView.sectionFooterHeight = Layout.interRowSpacing
        self.tableView.contentInset.top = Layout.interRowSpacing
        self.tableView.register(AllDomainsListTableViewCell.self, forCellReuseIdentifier: CellIdentifiers.myDomain)
        self.tableView.register(AllDomainsListActivityIndicatorTableViewCell.self, forCellReuseIdentifier: CellIdentifiers.activityIndicator)
        self.tableView.separatorStyle = .none
        self.view.addSubview(tableView)
        self.view.pinSubviewToAllEdges(tableView)
        self.view.backgroundColor = tableView.backgroundColor
    }

    private func setupEmptyView() {
        self.emptyView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(emptyView)
        NSLayoutConstraint.activate([
            self.emptyView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            self.emptyView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            self.emptyView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor, constant: Length.Padding.double),
            self.emptyView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor, constant: -Length.Padding.double)
        ])
    }

    /// Force the navigation bar separator to be always visible.
    private func setupNavigationBarAppearance() {
        let appearance = self.navigationController?.navigationBar.standardAppearance
        self.navigationItem.scrollEdgeAppearance = appearance
        self.navigationItem.compactScrollEdgeAppearance = appearance
    }

    private func setupRefreshControl() {
        let action = UIAction { [weak self] action in
            guard let self, let refreshControl = action.sender as? UIRefreshControl else {
                return
            }
            self.tableView.sendSubviewToBack(refreshControl)
            self.viewModel.loadData()
        }
        self.refreshControl.addAction(action, for: .valueChanged)
        self.tableView.addSubview(refreshControl)
    }

    // MARK: - Reacting to State Changes

    private func observeState() {
        self.viewModel.$state.sink { [weak self] state in
            guard let self else {
                return
            }
            self.state = state
            switch state {
            case .normal, .loading:
                self.refreshControl.endRefreshing()
                self.tableView.isHidden = false
                self.tableView.reloadData()
            case .message(let viewModel):
                self.tableView.isHidden = true
                self.emptyView.update(with: viewModel)
            }
            self.emptyView.isHidden = !tableView.isHidden
        }.store(in: &cancellable)
    }

    // MARK: - Navigation

    private func navigateToAddDomain() {
        AllDomainsAddDomainCoordinator.presentAddDomainFlow(in: self)
    }

    private func navigateToDomainDetails(with viewModel: Domain) {
        guard let navigationController = navigationController else {
            self.crashLogger.logMessage("Failed to navigate to Domain Details screen from All Domains screen", level: .error)
            return
        }
        let domain = viewModel.domain
        let destination = DomainDetailsWebViewController(
            domain: domain.domain,
            siteSlug: domain.siteSlug,
            type: domain.type,
            analyticsSource: Constants.analyticsSource
        )
        destination.configureSandboxStore {
            navigationController.pushViewController(destination, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource

extension AllDomainsListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Workaround to change the section height using `tableView.sectionHeaderHeight`.
        return UIView()
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Workaround to change the footer height using `tableView.sectionFooterHeight`.
        return UIView()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        switch state {
        case .normal(let domains): return domains.count
        case .loading: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch state {
        case .loading:
            return tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.activityIndicator, for: indexPath)
        case .normal(let domains):
            let domain = domains[indexPath.section]
            let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.myDomain, for: indexPath) as! AllDomainsListTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.update(with: domain.row, parent: self)
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch state {
        case .normal(let domains):
            let domain = domains[indexPath.section]
            self.navigateToDomainDetails(with: domain)
        default:
            break
        }
    }
}

// MARK: - UISearchControllerDelegate & UISearchBarDelegate

extension AllDomainsListViewController: UISearchControllerDelegate, UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.viewModel.search(searchText)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.viewModel.search(nil)
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        WPAnalytics.track(.myDomainsSearchDomainTapped)
    }
}
