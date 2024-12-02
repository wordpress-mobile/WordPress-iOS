import UIKit
import WordPressFlux
import Gridicons

class PluginDirectoryViewController: UITableViewController {

    private let viewModel: PluginDirectoryViewModel
    private var viewModelReceipt: Receipt?
    private var tableViewModel: ImmuTable!

    private let searchThrottle = Scheduler(seconds: 0.5)

    init(site: JetpackSiteRef, store: PluginStore = StoreContainer.shared.plugin) {
        viewModel = PluginDirectoryViewModel(site: site, store: store)

        super.init(style: .plain)
        tableViewModel = viewModel.tableViewModel(presenter: self)
        title = NSLocalizedString("Plugins", comment: "Title for the plugin directory")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        definesPresentationContext = true

        viewModelReceipt = viewModel.onChange { [weak self] in
            self?.reloadTable()
        }

        viewModel.noResultsDelegate = self

        tableView.rowHeight = Constants.rowHeight
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.separatorInset = Constants.separatorInset

        ImmuTable.registerRows([CollectionViewContainerRow<PluginDirectoryCollectionViewCell, PluginDirectoryEntry>.self],
                               tableView: tableView)

        tableViewModel = viewModel.tableViewModel(presenter: self)
        navigationItem.searchController = searchController
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.hidesSearchBarWhenScrolling = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationItem.hidesSearchBarWhenScrolling = true
    }

    private func reloadTable() {
        tableViewModel = viewModel.tableViewModel(presenter: self)

        tableView.reloadData()
    }

    private lazy var searchController: UISearchController = {
        let resultsController = PluginListViewController(site: viewModel.site, query: .feed(type: .search(term: "")))
        let controller = UISearchController(searchResultsController: resultsController)
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchResultsUpdater = self
        controller.delegate = self
        return controller
    }()

    private enum Constants {
        static var rowHeight: CGFloat = 256
        static var separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}

extension PluginDirectoryViewController {
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = tableViewModel.rowAtIndexPath(indexPath)
        row.action?(row)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
}

extension PluginDirectoryViewController: UISearchControllerDelegate {
    func didPresentSearchController(_ searchController: UISearchController) {
        WPAppAnalytics.track(.pluginSearchPerformed, withBlogID: viewModel.site.siteID as NSNumber)
    }
}

extension PluginDirectoryViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let pluginListViewController = searchController.searchResultsController as? PluginListViewController,
            let searchedText = searchController.searchBar.text else {
            return
        }

        searchThrottle.throttle {
            pluginListViewController.query = .feed(type: .search(term: searchedText))
        }
    }
}

extension PluginDirectoryViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        viewModel.reloadFailed()
    }
}

extension PluginDirectoryViewController: PluginPresenter {
    func present(plugin: Plugin, capabilities: SitePluginCapabilities) {
        guard navigationController?.topViewController == self else {
            // because of some work we're doing when presenting the VC, there might be a slight lag
            // between when a user taps on a plugin, and when it appears on screen — unfortunately enough
            // for users to not be sure whether the tap "registered".
            // this prevents from pushing the same screen multiple times when users taps again.
            return
        }

        let pluginVC = PluginViewController(plugin: plugin, capabilities: capabilities, site: viewModel.site)
        navigationController?.pushViewController(pluginVC, animated: true)
    }

    func present(directoryEntry: PluginDirectoryEntry) {
        guard navigationController?.topViewController == self else {
            return
        }

        let pluginVC = PluginViewController(directoryEntry: directoryEntry, site: viewModel.site)
        navigationController?.pushViewController(pluginVC, animated: true)
    }

}

extension PluginDirectoryViewController: PluginListPresenter {
    func present(site: JetpackSiteRef, query: PluginQuery) {
        let listType: String?
        switch query {
        case .all:
            listType = "installed"
        case .featured:
            listType = "featured"
        case .feed(.popular):
            listType = "popular"
        case .feed(.newest):
            listType = "newest"
        default:
            listType = nil
        }

        if let listType {
            let properties = ["type": listType]
            let siteID: NSNumber? = (site.isSelfHostedWithoutJetpack ? nil : site.siteID) as NSNumber?

            WPAppAnalytics.track(.openedPluginList, withProperties: properties, withBlogID: siteID)
        }

        let listVC = PluginListViewController(site: site, query: query)
        navigationController?.pushViewController(listVC, animated: true)
    }
}

extension BlogDetailsViewController {

    @objc func makePluginDirectoryViewController(blog: Blog) -> PluginDirectoryViewController? {
        guard let site = JetpackSiteRef(blog: blog) else {
            return nil
        }

        return PluginDirectoryViewController(site: site)
    }
}
