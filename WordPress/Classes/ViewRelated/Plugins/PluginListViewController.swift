import UIKit
import WordPressKit
import WordPressFlux

class PluginListViewController: UITableViewController, ImmuTablePresenter {
    let site: JetpackSiteRef
    var query: PluginQuery {
        didSet {
            viewModel.query = query
        }
    }

    fileprivate var viewModel: PluginListViewModel
    fileprivate var tableViewModel = ImmuTable.Empty

    private let noResultsViewController = NoResultsViewController.controller()
    var viewModelStateChangeReceipt: Receipt?
    var viewModelChangeReceipt: Receipt?

    init(site: JetpackSiteRef, query: PluginQuery, store: PluginStore = StoreContainer.shared.plugin) {
        self.site = site
        self.query = query
        viewModel = PluginListViewModel(site: site, query: query, store: store)

        super.init(style: .grouped)

        title = viewModel.title
        noResultsViewController.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        ImmuTable.registerRows(PluginListViewModel.immutableRows, tableView: tableView)
        setupRefreshControl()

        viewModelStateChangeReceipt = viewModel.onStateChange { [weak self] (change) in
            self?.refreshModel(change: change)
        }
        viewModelChangeReceipt = viewModel.onChange { [weak self] in
            self?.updateRefreshControl()
        }

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 72

        updateRefreshControl()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshModel(change: .replace)
    }

    @objc func refresh() {
        viewModel.refresh()
    }

    private func updateNoResults() {
        noResultsViewController.removeFromView()

        if let noResultsViewModel = viewModel.noResultsViewModel {
            showNoResults(noResultsViewModel)
        }
    }

    private func showNoResults(_ viewModel: NoResultsViewController.Model) {
        noResultsViewController.bindViewModel(viewModel)
        tableView.addSubview(withFadeAnimation: noResultsViewController.view)
        addChildViewController(noResultsViewController)
        noResultsViewController.didMove(toParentViewController: self)
    }

    func refreshModel(change: PluginListViewModel.StateChange) {
        title = viewModel.title
        tableViewModel = viewModel.tableViewModel(presenter: self)
        switch change {
        case .replace:
            tableView.reloadData()
        case .selective(let changedRows):
            let indexPaths = changedRows.map({ IndexPath(row: $0, section: 0) })
            tableView.reloadRows(at: indexPaths, with: .none)
        }
        setupRefreshControl()
        updateNoResults()
    }

    private func setupRefreshControl() {
        if viewModel.currentState == .loading {
            refreshControl = nil
            return
        }

        if case .feed(let feedType) = query, case .search = feedType {
            refreshControl = nil
            return
        }

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(PluginListViewController.refresh), for: .valueChanged)
    }

    private func updateRefreshControl() {
        guard let refreshControl = refreshControl else {
                return
        }

        switch (viewModel.refreshing, refreshControl.isRefreshing) {
        case (true, false):
            refreshControl.beginRefreshing()
        case (false, true):
            refreshControl.endRefreshing()
        default:
            break
        }
    }
}

// MARK: - Table View Data Source
extension PluginListViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewModel.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewModel.sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = tableViewModel.rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reusableIdentifier, for: indexPath)

        row.configureCell(cell)

        return cell
    }
}

// MARK: - Table View Delegate
extension PluginListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = tableViewModel.rowAtIndexPath(indexPath)
        row.action?(row)
    }
}

// MARK: - NoResultsViewControllerDelegate

extension PluginListViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        let supportVC = SupportTableViewController()
        supportVC.showFromTabBar()
    }
}

// MARK: - PluginPresenter

extension PluginListViewController: PluginPresenter {
    func present(directoryEntry: PluginDirectoryEntry) {
        let controller = PluginViewController(directoryEntry: directoryEntry, site: site)

        if let presenting = presentingViewController as? PluginDirectoryViewController, let presentingNavVC = presenting.navigationController {
            // If we're presenting results of a search query, we don't have a navVC, need to push on the presenting one.
            presentingNavVC.pushViewController(controller, animated: true)
        } else {
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    func present(plugin: Plugin, capabilities: SitePluginCapabilities) {
        let controller = PluginViewController(plugin: plugin, capabilities: capabilities, site: site)
        navigationController?.pushViewController(controller, animated: true)
    }
}
