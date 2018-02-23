import UIKit
import WordPressFlux
import Gridicons

class PluginDirectoryViewController: UITableViewController {

    private let viewModel: PluginDirectoryViewModel
    private var viewModelReceipt: Receipt?
    private var immuHandler: ImmuTableViewHandler?

    init(site: JetpackSiteRef, store: PluginStore = StoreContainer.shared.plugin) {
        viewModel = PluginDirectoryViewModel(site: site, store: store)

        super.init(style: .plain)

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

        definesPresentationContext = true
        extendedLayoutIncludesOpaqueBars = true

        viewModelReceipt = viewModel.onChange { [weak self] in
            self?.reloadTable()
        }

        tableView.rowHeight = Constants.rowHeight
        tableView.separatorInset = Constants.separatorInset

        ImmuTable.registerRows([CollectionViewContainerRow<PluginDirectoryCollectionViewCell, PluginDirectoryEntry>.self,
                                TextRow.self],
                               tableView: tableView)


        let handler = ImmuTableViewHandler(takeOver: self)
        handler.automaticallyDeselectCells = true
        handler.viewModel = viewModel.tableViewModel(presenter: self)

        immuHandler = handler

        navigationItem.rightBarButtonItem = searchBarButton

        setupSearchBar()
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    private func reloadTable() {
        immuHandler?.viewModel = viewModel.tableViewModel(presenter: self)
    }

    @objc private func searchButtonTapped() {
        searchController.isActive = true
        tableView.setContentOffset(.zero, animated: true)
    }

    private func setupSearchBar() {
        tableView.tableHeaderView = searchController.searchBar
        tableView.contentOffset = CGPoint(x: 0, y: searchController.searchBar.frame.height)
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
        searchBar.showsCancelButton = true
        searchBar.layer.borderWidth = 0

        return controller
    }()

    lazy var searchBarButton: UIBarButtonItem = {
        let icon = Gridicon.iconOfType(.search)

        let buttonItem = UIBarButtonItem(image: icon, style: .plain, target: self, action: #selector(searchButtonTapped))
        buttonItem.tintColor = .white

        return buttonItem
    }()

    private enum Constants {
        static var searchBarBackgroundColor = UIColor.black.withAlphaComponent(0.5)
        static var searchBarCornerRadius: CGFloat = 10
        static var rowHeight: CGFloat = 256
        static var separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

}

extension PluginDirectoryViewController: UISearchControllerDelegate {
    func didPresentSearchController(_ searchController: UISearchController) {
        // This is required when programmatically `activate`ing the Search controller,
        // e.g. when the user taps on the "Search" icon in the navbar
        DispatchQueue.main.async {
            searchController.searchBar.becomeFirstResponder()
        }
    }
}

extension PluginDirectoryViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let pluginListViewController = searchController.searchResultsController as? PluginListViewController,
            let searchedText = searchController.searchBar.text else {
            return
        }

        pluginListViewController.query = .feed(type: .search(term: searchedText))
    }

}

extension PluginDirectoryViewController: PluginPresenter {
    func present(plugin: Plugin, capabilities: SitePluginCapabilities) {
        let pluginVC = PluginViewController(plugin: plugin, capabilities: capabilities, site: viewModel.site)
        navigationController?.pushViewController(pluginVC, animated: true)
    }

    func present(directoryEntry: PluginDirectoryEntry) {
        let pluginVC = PluginViewController(directoryEntry: directoryEntry, site: viewModel.site)
        navigationController?.pushViewController(pluginVC, animated: true)
    }

}

extension PluginDirectoryViewController: PluginListPresenter {
    func present(site: JetpackSiteRef, query: PluginQuery) {
        let listVC = PluginListViewController(site: site, query: query)
        navigationController?.pushViewController(listVC, animated: true)
    }
}
