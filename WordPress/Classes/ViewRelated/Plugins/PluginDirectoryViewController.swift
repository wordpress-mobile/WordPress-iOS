import UIKit
import WordPressFlux
import Gridicons

class PluginDirectoryViewController: UITableViewController {

    private let viewModel: PluginDirectoryViewModel
    private var viewModelReceipt: Receipt?
    private var tableViewModel: ImmuTable!
    private var searchWrapperView: SearchWrapperView!

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

    @objc convenience init?(blog: Blog) {
        guard let site = JetpackSiteRef(blog: blog) else {
            return nil
        }

        self.init(site: site)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.configureColors(for: nil, andTableView: tableView)

        definesPresentationContext = true
        extendedLayoutIncludesOpaqueBars = true

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
        setupSearchBar()
    }

    private func reloadTable() {
        tableViewModel = viewModel.tableViewModel(presenter: self)

        tableView.reloadData()
    }

    private func setupSearchBar() {
        let containerView = SearchWrapperView(frame: CGRect(origin: .zero,
                                                            size: CGSize(width: tableView.frame.width,
                                                                         height: searchController.searchBar.frame.height)))

        containerView.addSubview(searchController.searchBar)
        tableView.tableHeaderView = containerView
        tableView.scrollIndicatorInsets.top = searchController.searchBar.bounds.height
        // for some... particlar reason, which I haven't been able to fully track down, if the searchBar is added directly
        // as the tableHeaderView, the UITableView sort of freaks out and adds like 400pts of random padding
        // below the content of the tableView. Wrapping it in this container fixes it ¯\_(ツ)_/¯

        searchWrapperView = containerView
    }

    private lazy var searchController: UISearchController = {
        let resultsController = PluginListViewController(site: viewModel.site, query: .feed(type: .search(term: "")))

        let controller = UISearchController(searchResultsController: resultsController)
        controller.obscuresBackgroundDuringPresentation = false
        controller.dimsBackgroundDuringPresentation = false
        controller.searchResultsUpdater = self
        controller.delegate = self

        let searchBar = controller.searchBar
        WPStyleGuide.configureSearchBar(searchBar)

        return controller
    }()

    private enum Constants {
        static var rowHeight: CGFloat = 256
        static var separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    fileprivate func updateTableHeaderSize() {
        if searchController.isActive {
            // Account for the search bar being moved to the top of the screen.
            searchWrapperView.frame.size.height = (searchController.searchBar.bounds.height + searchController.searchBar.frame.origin.y) - topLayoutGuide.length
        } else {
            searchWrapperView.frame.size.height = searchController.searchBar.bounds.height
        }

        // Resetting the tableHeaderView is necessary to get the new height to take effect
        tableView.tableHeaderView = searchWrapperView
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
        // This is required when programmatically `activate`ing the Search controller,
        // e.g. when the user taps on the "Search" icon in the navbar
        DispatchQueue.main.async {
            searchController.searchBar.becomeFirstResponder()
        }
        if #available(iOS 11.0, *) {
            updateTableHeaderSize()

            tableView.scrollIndicatorInsets.top = searchWrapperView.bounds.height
            tableView.contentInset.top = 0
        }
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        updateTableHeaderSize()
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
            pluginListViewController.tableView.contentInset.top = self.searchWrapperView.bounds.height
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

        if let listType = listType {
            let properties = ["type": listType]
            WPAppAnalytics.track(.openedPluginList, withProperties: properties, withBlogID: site.siteID as NSNumber)
        }

        let listVC = PluginListViewController(site: site, query: query)
        navigationController?.pushViewController(listVC, animated: true)
    }
}
