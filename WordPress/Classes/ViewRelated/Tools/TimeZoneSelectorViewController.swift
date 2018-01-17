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

    let changeDispatcher = Dispatcher<Void>()

    func tableViewModel(selectionHandler: @escaping (WPTimeZone) -> Void) -> ImmuTable {
        guard case .ready(let groups) = state else {
            return .Empty
        }

        return ImmuTable(
            sections: groups.map({ (group) -> ImmuTableSection in
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
}

class TimeZoneSelectorViewController: UITableViewController {
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

    init(selectedValue: String?, onSelectionChanged: @escaping (WPTimeZone) -> Void) {
        self.onSelectionChanged = onSelectionChanged
        self.viewModel = TimeZoneSelectorViewModel(state: .loading, selectedValue: selectedValue)
        super.init(style: .grouped)
        title = NSLocalizedString("Time Zone", comment: "Title for the time zone selector")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ImmuTable.registerRows([CheckmarkRow.self], tableView: tableView)
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        let store = StoreContainer.shared.timezone
        storeReceipt = store.onChange { [weak self] in
            guard let controller = self else {
                return
            }
            controller.viewModel = TimeZoneSelectorViewModel(
                state: TimeZoneSelectorViewModel.State.with(storeState: store.state),
                selectedValue: controller.viewModel.selectedValue
            )
        }
        queryReceipt = store.query(TimeZoneQuery())
    }
}
