import UIKit
import WordPressFlux
import Gridicons

class PluginDirectoryViewController: UITableViewController {

    private let viewModel: PluginDirectoryViewModel
    private var viewModelReceipt: Receipt?
    private var immuHandler: ImmuTableViewHandler?

    private lazy var searchController: UISearchController = {
        let resultsController = PluginListViewController(site: viewModel.site, query: .feed(type: .search(term: "")))

        let controller = UISearchController(searchResultsController: resultsController)
        controller.obscuresBackgroundDuringPresentation = false
        controller.dimsBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false
        controller.searchResultsUpdater = self
        controller.delegate = self

        let searchBar = controller.searchBar
        WPStyleGuide.configureSearchBar(searchBar)
        searchBar.showsCancelButton = true
        searchBar.barTintColor = WPStyleGuide.wordPressBlue()
        searchBar.layer.borderWidth = 0

        return controller
    }()

    init(site: JetpackSiteRef, store: PluginStore = StoreContainer.shared.plugin) {
        viewModel = PluginDirectoryViewModel(site: site, store: store)

        super.init(style: .plain)

        title = NSLocalizedString("Plugins", comment: "Title for the plugin directory")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.shadowImage = UIImage()

        // There isn't a good way of styling a one, particular UISearchBar, without reaching deep into
        // it's own subview hierarchy (though we still need to do that to change the background color in iOS11...)

        // We're gonna override the appearance of the "Cancel" button here, then restore the app-wide
        // one on `viewWillDisappear(_:)`.

        let barButtonTitleAttributes: [NSAttributedStringKey: Any] = [.font: WPStyleGuide.fontForTextStyle(.headline),
                                                                      .foregroundColor: UIColor.white]


        let barButtonItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        barButtonItemAppearance.setTitleTextAttributes(barButtonTitleAttributes, for: UIControlState())

        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = WPStyleGuide.defaultSearchBarTextAttributes(UIColor.white)
    }

    override func viewWillDisappear(_ animated: Bool) {
        WPStyleGuide.configureSearchBarAppearance()
    }

    @objc convenience init?(blog: Blog) {
        guard let site = JetpackSiteRef(blog: blog) else {
            return nil
        }

        self.init(site: site)
    }

    lazy var searchBarButton: UIBarButtonItem = {
        let icon = Gridicon.iconOfType(.search)

        let buttonItem = UIBarButtonItem(image: icon, style: .plain, target: self, action: #selector(searchButtonTapped))
        buttonItem.tintColor = .white

        return buttonItem
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        definesPresentationContext = true
        tableView.backgroundColor = .white

        viewModelReceipt = viewModel.onChange { [weak self] in
            self?.reloadTable()
        }

        tableView.rowHeight = 256
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        ImmuTable.registerRows([CollectionViewContainerRow<PluginDirectoryCollectionViewCell, PluginDirectoryEntry>.self,
                                TextRow.self],
                               tableView: tableView)


        let handler = ImmuTableViewHandler(takeOver: self)
        handler.automaticallyDeselectCells = true
        handler.viewModel = viewModel.tableViewModel(presenter: self)

        immuHandler = handler

        navigationItem.rightBarButtonItem = searchBarButton
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    private func reloadTable() {
        immuHandler?.viewModel = viewModel.tableViewModel(presenter: self)
    }

    @objc private func searchButtonTapped() {
        toggleSearchBar()
    }

    private func toggleSearchBar() {
        if #available(iOS 11.0, *) {

            if navigationItem.searchController == nil {
                showSearchBar()
            } else {
                hideSearchBar()
            }

        } else {

            let searchBar = searchController.searchBar
            if searchBar.superview != nil {
                // Fallback on earlier versions
                searchBar.removeFromSuperview()
                tableView.tableHeaderView = nil
            }

            let height = searchBar.bounds.height

            searchBar.bounds.size.height = 0

            UIView.animate(withDuration: 0.3, animations: {
                self.tableView.tableHeaderView = searchBar
                searchBar.bounds.size.height = height
            })
        }
    }

    private func showSearchBar() {
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = false
            navigationItem.searchController = searchController
            navigationItem.searchController?.searchBar.becomeFirstResponder()

            // This is extremely fragile and almost guaranteed to break in a future iOS update, but I couldn't
            // really find a way to achieve it any other way. (Setting `appearance` on `UITextField` contained
            // in a `UISearchBar` didn't work).
            // Inspired by https://stackoverflow.com/questions/45663169/uisearchcontroller-ios-11-customization
            if let textfield = searchController.searchBar.value(forKey: "searchField") as? UITextField {
                if let backgroundView = textfield.subviews.first {
                    backgroundView.backgroundColor = UIColor.init(fromRGBColorWithRed: 27.0/255.0, green: 147.0/255.0, blue: 196.0/255.0)
                    backgroundView.layer.cornerRadius = 10;
                    backgroundView.clipsToBounds = true;
                }
            }
        }
    }

    private func hideSearchBar() {
        if #available(iOS 11.0, *) {
            navigationItem.searchController?.isActive = false

            self.navigationItem.searchController = UISearchController(searchResultsController: nil)
            self.navigationItem.searchController = nil
            // For some reason, just setting the controller to `nil` doesn't resize the UINavigationBar and leaves a huge, ugly gap.
            // Setting it to a "dummy", empty search controller and _then_ `nil`ing it out fixes it.
        } else {
           dump("whaaat")
        }
    }
}

extension PluginDirectoryViewController: UISearchControllerDelegate {

    func didDismissSearchController(_ searchController: UISearchController) {
        hideSearchBar()
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
