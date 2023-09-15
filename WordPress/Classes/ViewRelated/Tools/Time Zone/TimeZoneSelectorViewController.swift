import UIKit
import WordPressFlux

class TimeZoneSelectorViewController: UITableViewController, UISearchResultsUpdating {
    var storeReceipt: Receipt?
    var queryReceipt: Receipt?

    var onSelectionChanged: ((WPTimeZone) -> Void)
    var viewModel: TimeZoneSelectorViewModel {
        didSet {
            handler.viewModel = viewModel.tableViewModel(selectionHandler: { [weak self] (selectedTimezone) in
                self?.viewModel.selectedValue = selectedTimezone.value
                self?.onSelectionChanged(selectedTimezone)
            })
            tableView.reloadData()
        }
    }

    fileprivate lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    private var noResultsViewController: NoResultsViewController?

    private let searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        return controller
    }()

    init(selectedValue: String?, onSelectionChanged: @escaping (WPTimeZone) -> Void) {
        self.onSelectionChanged = onSelectionChanged
        self.viewModel = TimeZoneSelectorViewModel(state: .loading, selectedValue: selectedValue, filter: nil)
        super.init(style: .grouped)
        searchController.searchResultsUpdater = self
        title = NSLocalizedString("Time Zone", comment: "Title for the time zone selector")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ImmuTable.registerRows([TimeZoneRow.self], tableView: tableView)
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureSearchBar(searchController.searchBar)

        configureTableHeaderView()

        tableView.backgroundView = UIView()

        let store = StoreContainer.shared.timezone
        storeReceipt = store.onChange { [weak self] in
            self?.updateViewModel()
        }
        queryReceipt = store.query(TimeZoneQuery())
        updateViewModel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutHeaderView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.isActive = false
    }

    private func configureTableHeaderView() {
        let timeZoneIdentifier = TimeZone.current.identifier
        guard let headerView = TimeZoneSearchHeaderView.makeFromNib(searchBar: searchController.searchBar,
                                                                    timezone: timeZoneIdentifier) else {
            // fallback to default SearchBar if TimeZoneSearchHeaderView cannot be created
            tableView.tableHeaderView = searchController.searchBar
            return
        }

        headerView.tapped = { [weak self] in
            // check if currentTimeZoneIdentifier has a WPTimeZone instance
            if let selectedTimezone = self?.viewModel.getTimeZoneForIdentifier(timeZoneIdentifier) {
                self?.viewModel.selectedValue = timeZoneIdentifier
                self?.onSelectionChanged(selectedTimezone)
            }
        }

        tableView.tableHeaderView = headerView
    }

    func updateSearchResults(for searchController: UISearchController) {
        updateViewModel()
    }

    func updateViewModel() {
        let store = StoreContainer.shared.timezone
        viewModel = TimeZoneSelectorViewModel(
            state: TimeZoneSelectorViewModel.State.with(storeState: store.state),
            selectedValue: viewModel.selectedValue,
            filter: searchFilter
        )
        updateNoResults()
    }

    var searchFilter: String? {
        guard searchController.isActive else {
            return nil
        }
        return searchController.searchBar.text?.nonEmptyString()
    }

}

// MARK: - No Results Handling

private extension TimeZoneSelectorViewController {

    func updateNoResults() {
        noResultsViewController?.removeFromView()
        if let noResultsViewModel = viewModel.noResultsViewModel {
            showNoResults(noResultsViewModel)
        }
    }

    private func showNoResults(_ viewModel: NoResultsViewController.Model) {

        if noResultsViewController == nil {
            noResultsViewController = NoResultsViewController.controller()
            noResultsViewController?.delegate = self
        }

        guard let noResultsViewController = noResultsViewController else {
            return
        }

        noResultsViewController.bindViewModel(viewModel)

        tableView.addSubview(withFadeAnimation: noResultsViewController.view)
        addChild(noResultsViewController)
        noResultsViewController.didMove(toParent: self)
    }

}

// MARK: - NoResultsViewControllerDelegate

extension TimeZoneSelectorViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        let supportVC = SupportTableViewController()
        supportVC.showFromTabBar()
    }
}

// MARK: - UITableViewDelegate

extension TimeZoneSelectorViewController {

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
