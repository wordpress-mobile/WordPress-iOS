import UIKit
import WordPressKit
import WordPressFlux

class PluginListViewController: UITableViewController, ImmuTablePresenter {
    let site: JetpackSiteRef

    fileprivate var viewModel: PluginListViewModel
    fileprivate var tableViewModel = ImmuTable.Empty

    fileprivate let noResultsView = WPNoResultsView()
    var viewModelStateChangeReceipt: Receipt?
    var viewModelChangeReceipt: Receipt?

    init(site: JetpackSiteRef, query: PluginQuery, store: PluginStore = StoreContainer.shared.plugin) {
        self.site = site
        viewModel = PluginListViewModel(site: site, query: query, store: store)

        super.init(style: .grouped)

        title = NSLocalizedString("Plugins", comment: "Title for the plugin manager")
        noResultsView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(PluginListViewController.refresh), for: .valueChanged)

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        ImmuTable.registerRows(PluginListViewModel.immutableRows, tableView: tableView)
        viewModelStateChangeReceipt = viewModel.onStateChange { [weak self] (change) in
            self?.refreshModel(change: change)
        }
        viewModelChangeReceipt = viewModel.onChange { [weak self] in
            self?.updateRefreshControl()
        }
        refreshModel(change: .replace)
        updateRefreshControl()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshModel(change: .replace)
    }

    @objc func refresh() {
        ActionDispatcher.dispatch(PluginAction.refreshPlugins(site: site))
    }

    func updateNoResults() {
        if let noResultsViewModel = viewModel.noResultsViewModel {
            showNoResults(noResultsViewModel)
        } else {
            hideNoResults()
        }
    }

    func showNoResults(_ viewModel: WPNoResultsView.Model) {
        noResultsView.bindViewModel(viewModel)
        if noResultsView.isDescendant(of: tableView) {
            noResultsView.centerInSuperview()
        } else {
            tableView.addSubview(withFadeAnimation: noResultsView)
        }
    }

    func hideNoResults() {
        noResultsView.removeFromSuperview()
    }

    func refreshModel(change: PluginListViewModel.StateChange) {
        tableViewModel = viewModel.tableViewModel(presenter: self)
        switch change {
        case .replace:
            tableView.reloadData()
        case .selective(let changedRows):
            let indexPaths = changedRows.map({ IndexPath(row: $0, section: 0) })
            tableView.reloadRows(at: indexPaths, with: .none)
        }
        updateNoResults()
    }

    func updateRefreshControl() {
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

// MARK: - WPNoResultsViewDelegate

extension PluginListViewController: WPNoResultsViewDelegate {
    func didTap(_ noResultsView: WPNoResultsView!) {
        let supportVC = SupportViewController()
        supportVC.showFromTabBar()
    }
}

// MARK: - PluginPresenter

extension PluginListViewController: PluginPresenter {
    func present(directoryEntry: PluginDirectoryEntry) {
        let controller = PluginViewController(directoryEntry: directoryEntry, site: site)
        navigationController?.pushViewController(controller, animated: true)
    }

    func present(plugin: Plugin, capabilities: SitePluginCapabilities) {
        let controller = PluginViewController(plugin: plugin, capabilities: capabilities, site: site)
        navigationController?.pushViewController(controller, animated: true)
    }
}
