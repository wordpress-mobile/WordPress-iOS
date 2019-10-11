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

    var noResultsViewModel: NoResultsViewController.Model? {
        switch state {
        case .loading:
            return NoResultsViewController.Model(title: LocalizedText.loadingTitle, accessoryView: NoResultsViewController.loadingAccessoryView())
        case .ready:
            return nil
        case .error:
            let appDelegate = WordPressAppDelegate.shared
            if (appDelegate?.connectionAvailable)! {
                return NoResultsViewController.Model(title: LocalizedText.errorTitle,
                                                     subtitle: LocalizedText.errorSubtitle,
                                                     buttonText: LocalizedText.buttonText)
            } else {
                return NoResultsViewController.Model(title: LocalizedText.noConnectionTitle,
                                                     subtitle: LocalizedText.noConnectionSubtitle)
            }
        }
    }

    struct LocalizedText {
        static let loadingTitle = NSLocalizedString("Loading...", comment: "Text displayed while loading time zones")
        static let errorTitle = NSLocalizedString("Oops", comment: "Title for the view when there's an error loading time zones")
        static let errorSubtitle = NSLocalizedString("There was an error loading time zones", comment: "Error message when time zones can't be loaded")
        static let buttonText = NSLocalizedString("Contact support", comment: "Title of a button. A call to action to contact support for assistance.")
        static let noConnectionTitle = NSLocalizedString("No connection", comment: "Title for the error view when there's no connection")
        static let noConnectionSubtitle = NSLocalizedString("An active internet connection is required", comment: "Error message when loading failed because there's no connection")
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
        ImmuTable.registerRows([CheckmarkRow.self], tableView: tableView)
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureSearchBar(searchController.searchBar)
        tableView.tableHeaderView = searchController.searchBar
        tableView.backgroundView = UIView()

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
