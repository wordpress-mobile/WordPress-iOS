import UIKit
import WordPressKit

class PluginListViewController: UITableViewController, ImmuTablePresenter {
    let siteID: Int
    let store: PluginStore

    fileprivate lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    fileprivate var viewModel: PluginListViewModel = .loading {
        didSet {
            handler.viewModel = viewModel.tableViewModel(presenter: self)
            updateNoResults()
        }
    }

    fileprivate let noResultsView = WPNoResultsView()
    private var listener: FluxStore.Listener!
    private var dispatchToken: FluxDispatcher.DispatchToken!

    init(siteID: Int, store: PluginStore = StoreContainer.shared.plugin) {
        self.siteID = siteID
        self.store = store
        super.init(style: .grouped)
        title = NSLocalizedString("Plugins", comment: "Title for the plugin manager")
        noResultsView.delegate = self
        listener = store.onChange { [weak self] in
            self?.refreshModel()
        }
        dispatchToken = FluxDispatcher.global.register(callback: { [weak self] (action) in
            self?.onDispatch(action: action)
        })
        refreshModel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init?(blog: Blog) {
        precondition(blog.dotComID != nil)

        self.init(siteID: Int(blog.dotComID!))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        ImmuTable.registerRows([PluginListRow.self], tableView: tableView)
        handler.viewModel = viewModel.tableViewModel(presenter: self)
        updateNoResults()
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
        viewModel = PluginListViewModel(plugins: store.getPlugins(siteID: siteID))
    }

    func onDispatch(action: FluxAction) {
        guard let pluginAction = action as? PluginAction else {
            return
        }
        switch pluginAction {
        case .receivePluginsFailed(let siteID, let error):
            guard siteID == self.siteID else {
                return
            }
            viewModel = .error(error.localizedDescription)
        default:
            return
        }
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
        let controller = PluginViewController(plugin: plugin, capabilities: capabilities, siteID: siteID)
        navigationController?.pushViewController(controller, animated: true)
    }
}
