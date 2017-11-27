import UIKit
import WordPressKit
import WordPressFlux

class PluginListViewController: UITableViewController, ImmuTablePresenter {
    let site: JetpackSiteRef

    fileprivate lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    fileprivate var viewModel: PluginListViewModel

    fileprivate let noResultsView = WPNoResultsView()
    var viewModelReceipt: Receipt?

    init(site: JetpackSiteRef, store: PluginStore = StoreContainer.shared.plugin) {
        self.site = site
        viewModel = PluginListViewModel(site: site, store: store)

        super.init(style: .grouped)

        title = NSLocalizedString("Plugins", comment: "Title for the plugin manager")
        noResultsView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc convenience init?(blog: Blog) {
        guard let site = JetpackSiteRef(blog: blog) else {
            return nil
        }

        self.init(site: site)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        ImmuTable.registerRows(PluginListViewModel.immutableRows, tableView: tableView)
        viewModelReceipt = viewModel.onChange { [weak self] in
            self?.refreshModel()
        }
        refreshModel()
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

    func refreshModel() {
        handler.viewModel = viewModel.tableViewModel(presenter: self)
        updateNoResults()
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
    func present(plugin: PluginState, capabilities: SitePluginCapabilities) {
        let controller = PluginViewController(plugin: plugin, capabilities: capabilities, site: site)
        navigationController?.pushViewController(controller, animated: true)
    }
}
