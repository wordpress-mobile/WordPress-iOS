import UIKit

class TimeZoneSelectorViewController: UITableViewController, ImmuTablePresenter {

    /// The blog's current timezone
    private var timeZoneSelected: TimeZoneSelected?
    /// case .timezoneString will be set to a non empty string
    /// if user selects anything other than Manual Offset section
    /// case .manualOffset will be set if users selects anything from Manual Offset section
    private var onChange: ((TimeZoneSelected) -> Void)!

    /// ImmuTableViewHandler, takes over the datasource, delegate from this VC
    private lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    private var viewModel: TimezoneSelectorViewModel = .loading {
        didSet {
            handler.viewModel = viewModel.tableViewModel
            updateNoResults()
        }
    }

    /// Show an intermittent loading state
    private let noResultsView = WPNoResultsView()

    private let estimatedRowHeight: CGFloat = 45.0

    public convenience init(timeZoneSelected: TimeZoneSelected?,
                     onChange: @escaping ((TimeZoneSelected) -> Void)) {
        self.init(style: .grouped)
        self.timeZoneSelected = timeZoneSelected
        self.onChange = onChange

    }

    override func viewDidLoad() {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = estimatedRowHeight

        title = NSLocalizedString("Site Timezone", comment: "Title for the timezone selector")
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        ImmuTable.registerRows([CheckmarkRow.self], tableView: tableView)
        handler.viewModel = viewModel.tableViewModel
        updateNoResults()
        loadData()
    }

    // MARK: Helper methods
    private func loadData() {
        TimeZoneService().fetchTimeZoneList(success: { [weak self] (allTimezones) in

            self?.viewModel = .ready(allTimezones, self?.timeZoneSelected, self?.onChange)
        }) { [weak self] (error) in
            self?.viewModel = .error(String(describing: error))
        }
    }

    // MARK: NoResultsView methods
    private func updateNoResults() {
        if let noResultsViewModel = viewModel.noResultsViewModel {
            showNoResults(noResultsViewModel)
        } else {
            hideNoResults()
        }
    }

    private func showNoResults(_ viewModel: WPNoResultsView.Model) {
        noResultsView.bindViewModel(viewModel)
        if noResultsView.isDescendant(of: tableView) {
            noResultsView.centerInSuperview()
        } else {
            tableView.addSubview(withFadeAnimation: noResultsView)
        }
    }

    private func hideNoResults() {
        noResultsView.removeFromSuperview()
    }
}
