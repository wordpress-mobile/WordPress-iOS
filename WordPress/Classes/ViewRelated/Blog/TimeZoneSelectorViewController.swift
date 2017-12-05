import UIKit

class TimeZoneSelectorViewController: UITableViewController, ImmuTablePresenter {

    /// The blog's current timezone. If no timezone string is set, then the manual offset value will be used.
    private var initialTimeZone: String?
    /// The blog's manual GMT offset. If timezone string is set, this value will be nil
    private var initialManualOffset: NSNumber?

    /// timezoneString will be set to a non empty string
    /// if user selects anything other than Manual Offset section
    /// manualOffset will be set if users selects anything from Manual Offset section
    private var onChange: ((_ timezoneString: String, _ manualOffset: NSNumber?) -> Void)!

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

    @objc public convenience init(timeZoneString: String?,
                     manualOffset: NSNumber?,
                     onChange: @escaping ((_ timezoneString: String, _ manualOffset: NSNumber?) -> Void)) {
        self.init(style: .grouped)
        self.initialTimeZone = timeZoneString
        self.initialManualOffset = manualOffset
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
    /// If no data exists in DB, make an API call to fetch and save the data, then display
    /// otherwise fetch data from DB and display
    private func loadData() {
        let allTimezones = viewModel.fetchTimezones()
        if allTimezones.count == 0 {
            refreshData()
        } else {
            viewModel = .ready(allTimezones, initialTimeZone, initialManualOffset, onChange)
        }
    }

    /// Helper method to call API and save the data to DB
    private func refreshData() {
        let api = ServiceRemoteWordPressComREST.anonymousWordPressComRestApi(withUserAgent: WPUserAgent.wordPress())!
        let remoteService = BlogServiceRemoteREST(wordPressComRestApi: api, siteID: NSNumber(value: 0))
        remoteService.fetchTimeZoneList(success: { [weak self] (resultsDict) in
            self?.viewModel.insertDataToDB(resultsDict: resultsDict)
            self?.loadData()
            }, failure: { [weak self] (error) in
                DDLogError("Error loading timezones: \(error)")
                self?.viewModel = .error(String(describing: error))
        })
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
