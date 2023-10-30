import UIKit
import Combine

final class AllDomainsListViewController: UIViewController {

    // MARK: - Types

    private enum Layout {
        static let interRowSpacing = Length.Padding.double
    }

    private enum CellIdentifiers {
        static let myDomain = String(describing: AllDomainsListTableViewCell.self)
        static let activityIndicator = String(describing: AllDomainsListActivityIndicatorTableViewCell.self)
    }

    typealias ViewModel = AllDomainsListViewModel

    // MARK: - Dependencies

    private let viewModel: ViewModel

    // MARK: - Views

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let emptyView = AllDomainsListEmptyView()

    // MARK: - Properties

    private lazy var state: ViewModel.State = viewModel.state

    // MARK: - Observation

    private var cancellable = Set<AnyCancellable>()

    // MARK: - Init

    init(viewModel: ViewModel = .init()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = Strings.title
        WPStyleGuide.configureColors(view: view, tableView: nil)
        self.setupSubviews()
        self.observeState()
        self.viewModel.loadData()
    }

    // MARK: - Setup Views

    private func setupSubviews() {
        self.setupBarButtonItems()
        self.setupSearchBar()
        self.setupTableView()
        self.setupEmptyView()
    }

    private func setupBarButtonItems() {
        self.navigationItem.rightBarButtonItem = .init(systemItem: .add)
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

    // MARK: - UI Updates

    private func observeState() {
        self.viewModel.$state.sink { [weak self] state in
            guard let self else {
                return
            }
            self.state = state
            switch state {
            case .normal, .loading:
                self.tableView.isHidden = false
                self.tableView.reloadData()
            case .empty(let viewModel):
                self.tableView.isHidden = true
                self.emptyView.update(with: viewModel)
            }
            self.emptyView.isHidden = !tableView.isHidden
        }.store(in: &cancellable)
    }
}

// MARK: - UITableViewDataSource

extension AllDomainsListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Workaround to accurately control section height using `tableView.sectionHeaderHeight`.
        return UIView()
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Workaround to accurately control footer height using `tableView.sectionFooterHeight`.
        return UIView()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        switch state {
        case .loading: return 1
        default: return viewModel.numberOfDomains
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch state {
        case .loading:
            return tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.activityIndicator, for: indexPath)
        default:
            let domain = viewModel.domain(atIndex: indexPath.section)
            let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.myDomain, for: indexPath) as! AllDomainsListTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.update(with: domain, parent: self)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UISearchControllerDelegate & UISearchBarDelegate

extension AllDomainsListViewController: UISearchControllerDelegate, UISearchBarDelegate {

}
