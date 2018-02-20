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

    override func viewWillAppear(_ animated: Bool) {
        // There isn't a good way of styling a one, particular UISearchBar, without reaching deep into
        // it's own subview hierarchy (though we still need to do that to change the background color in iOS11...)

        // We're gonna override the appearance of the "Cancel" button here, then restore the app-wide
        // one on `viewWillDisappear(_:)`.

        let barButtonTitleAttributes: [NSAttributedStringKey: Any] = [.font: WPStyleGuide.fontForTextStyle(.headline),
                                                                      .foregroundColor: UIColor.white]


        let barButtonItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        barButtonItemAppearance.setTitleTextAttributes(barButtonTitleAttributes, for: UIControlState())

        if #available(iOS 11.0, *) {
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = WPStyleGuide.defaultSearchBarTextAttributes(UIColor.white)
        }

    }

    override func viewWillDisappear(_ animated: Bool) {
        WPStyleGuide.configureSearchBarAppearance()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        definesPresentationContext = true
        extendedLayoutIncludesOpaqueBars = false
        tableView.backgroundColor = .white

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
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
            navigationItem.searchController = searchController


            // This is extremely fragile and almost guaranteed to break in a future iOS update, but I couldn't
            // really find a way to achieve it any other way. (Setting `appearance` on `UITextField` contained
            // in a `UISearchBar` didn't work).
            // Inspired by https://stackoverflow.com/questions/45663169/uisearchcontroller-ios-11-customization
            if let textfield = searchController.searchBar.value(forKey: "searchField") as? UITextField {
                if let backgroundView = textfield.subviews.first {
                    backgroundView.backgroundColor = Constants.searchBarBackgroundColor
                    backgroundView.layer.cornerRadius = Constants.searchBarCornerRadius
                    backgroundView.clipsToBounds = true
                }
            }
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }

        tableView.contentOffset = CGPoint(x: 0, y: searchController.searchBar.frame.height)
    }

    private lazy var searchController: UISearchController = {
        let resultsController = PluginListViewController(site: viewModel.site, query: .feed(type: .search(term: "")))

        let controller = UISearchController(searchResultsController: resultsController)
        controller.obscuresBackgroundDuringPresentation = false
        controller.dimsBackgroundDuringPresentation = false
        controller.searchResultsUpdater = self
        controller.delegate = self

        if #available(iOS 11, *) {
            controller.hidesNavigationBarDuringPresentation = true
        } else {
            controller.hidesNavigationBarDuringPresentation = false
        }

        let searchBar = controller.searchBar
        WPStyleGuide.configureSearchBar(searchBar)
        searchBar.showsCancelButton = true
        searchBar.barTintColor = WPStyleGuide.wordPressBlue()
        searchBar.isTranslucent = false
        searchBar.layer.borderWidth = 0
        searchBar.clipsToBounds = true

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
