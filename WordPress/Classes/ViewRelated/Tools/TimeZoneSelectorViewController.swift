import UIKit
import WordPressFlux

struct TimeZoneSelectorViewModel: Observable {
    enum State {
        case loading
        case ready([TimeZoneGroup])
        case error(Error)

        static func with(storeState: TimeZoneStoreState) -> State {
            switch storeState {
            case .empty, .loading:
                return .loading
            case .loaded(let groups):
                return .ready(groups)
            case .error(let error):
                return .error(error)
            }
        }
    }

    var state: State = .loading {
        didSet {
            emitChange()
        }
    }

    var selectedValue: String? {
        didSet {
            emitChange()
        }
    }

    var filter: String? {
        didSet {
            emitChange()
        }
    }

    let changeDispatcher = Dispatcher<Void>()

    var groups: [TimeZoneGroup] {
        guard case .ready(let groups) = state else {
            return []
        }
        return groups
    }

    var filteredGroups: [TimeZoneGroup] {
        guard let filter = filter else {
            return groups
        }

        return groups.compactMap({ (group) in
            if group.name.localizedCaseInsensitiveContains(filter) {
                return group
            } else {
                let timezones = group.timezones.filter({ $0.label.localizedCaseInsensitiveContains(filter) })
                if timezones.isEmpty {
                    return nil
                } else {
                    return TimeZoneGroup(name: group.name, timezones: timezones)
                }
            }
        })
    }

    func tableViewModel(selectionHandler: @escaping (WPTimeZone) -> Void) -> ImmuTable {
        return ImmuTable(
            sections: filteredGroups.map({ (group) -> ImmuTableSection in
                return ImmuTableSection(
                    headerText: group.name,
                    rows: group.timezones.map({ (timezone) -> ImmuTableRow in
                        return CheckmarkRow(title: timezone.label, checked: timezone.value == selectedValue, action: { _ in
                            selectionHandler(timezone)
                        })
                    }))
            })
        )
    }

    var noResultsViewModel: WPNoResultsView.Model? {
        switch state {
        case .loading:
            return WPNoResultsView.Model(
                title: NSLocalizedString("Loading...", comment: "Text displayed while loading time zones")
            )
        case .ready:
            return nil
        case .error:
            let appDelegate = WordPressAppDelegate.sharedInstance()
            if (appDelegate?.connectionAvailable)! {
                return WPNoResultsView.Model(
                    title: NSLocalizedString("Oops", comment: "Title for the view when there's an error loading time zones"),
                    message: NSLocalizedString("There was an error loading time zones", comment: "Error message when time zones can't be loaded"),
                    buttonTitle: NSLocalizedString("Contact support", comment: "Title of a button. A call to action to contact support for assistance.")
                )
            } else {
                return WPNoResultsView.Model(
                    title: NSLocalizedString("No connection", comment: "Title for the error view when there's no connection"),
                    message: NSLocalizedString("An active internet connection is required", comment: "Error message when loading failed because there's no connection")
                )
            }
        }
    }
}

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

    fileprivate let noResultsView = WPNoResultsView()

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
        noResultsView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ImmuTable.registerRows([CheckmarkRow.self], tableView: tableView)
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        WPStyleGuide.configureSearchBar(searchController.searchBar)
        tableView.tableHeaderView = searchController.searchBar

        let store = StoreContainer.shared.timezone
        storeReceipt = store.onChange { [weak self] in
            self?.updateViewModel()
        }
        queryReceipt = store.query(TimeZoneQuery())
        updateViewModel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.isActive = false
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

    var searchFilter: String? {
        guard searchController.isActive else {
            return nil
        }
        return searchController.searchBar.text?.nonEmptyString()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        noResultsView.centerInSuperview()
    }

}

// MARK: - WPNoResultsViewDelegate

extension TimeZoneSelectorViewController: WPNoResultsViewDelegate {
    func didTap(_ noResultsView: WPNoResultsView!) {
        let supportVC = SupportTableViewController()
        supportVC.showFromTabBar()
    }
}
