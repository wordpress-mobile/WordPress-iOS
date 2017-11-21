import UIKit
import WordPressKit

class PluginListViewController: UITableViewController, ImmuTablePresenter {
    @objc let siteID: Int
    @objc let service: PluginServiceRemote

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

    @objc init(siteID: Int, service: PluginServiceRemote) {
        self.siteID = siteID
        self.service = service
        super.init(style: .grouped)
        title = NSLocalizedString("Plugins", comment: "Title for the plugin manager")
        noResultsView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc convenience init?(blog: Blog) {
        precondition(blog.dotComID != nil)
        guard let api = blog.wordPressComRestApi(),
            let service = PluginServiceRemote(wordPressComRestApi: api),
            let dotComID = blog.dotComID?.intValue
        else {
            return nil
        }

        self.init(siteID: dotComID, service: service)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        ImmuTable.registerRows([PluginListRow.self], tableView: tableView)
        handler.viewModel = viewModel.tableViewModel(presenter: self)
        updateNoResults()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        service.getPlugins(siteID: siteID, success: { (plugins, capabilities) in
            self.viewModel = .ready(plugins, capabilities)
        }, failure: { error in
            DDLogError("Error loading plugins: \(error)")
            self.viewModel = .error(String(describing: error))
        })
    }

    @objc func updateNoResults() {
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

    @objc func hideNoResults() {
        noResultsView.removeFromSuperview()
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
        let controller = PluginViewController(plugin: plugin, capabilities: capabilities, siteID: siteID, service: service)
        navigationController?.pushViewController(controller, animated: true)
    }
}
