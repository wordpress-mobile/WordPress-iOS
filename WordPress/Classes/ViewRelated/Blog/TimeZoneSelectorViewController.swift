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

    /// common action passed to TimezoneListRow cells, executed on select of a cell
    private lazy var action: ImmuTableAction = { [weak self] (aRow) -> Void in
        self?.navigationController?.popViewController(animated: true)
        let timezoneValue: String = (aRow as? TimezoneListRow)?.timezoneValue ?? ""
        var timezoneString: String = ""
        var manualOffset: NSNumber?
        if let numberString = timezoneValue.components(separatedBy: "UTC").last,
            let floatVal = Float(numberString) {
            let manualOffsetNumber: NSNumber = NSNumber(value: floatVal)
            manualOffset = manualOffsetNumber
        } else {
            timezoneString = timezoneValue
        }
        self?.onChange?(timezoneString, manualOffset)
    }

    private var viewModel: TimezoneSelectorViewModel = .loading {
        didSet {
            handler.viewModel = viewModel.tableViewModel()
            updateNoResults()
        }
    }

    /// used to show an intermittent loading state
    private let noResultsView = WPNoResultsView()

    @objc public convenience init(timeZoneString: String?,
                     manualOffset: NSNumber?,
                     onChange: @escaping ((_ timezoneString: String, _ manualOffset: NSNumber?) -> Void)) {
        self.init(style: .grouped)
        self.initialTimeZone = timeZoneString
        self.initialManualOffset = manualOffset
        self.onChange = onChange

    }

    override func viewDidLoad() {
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 45.0

        title = NSLocalizedString("Time Zone", comment: "Title for the timezone selector")
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        ImmuTable.registerRows([TimezoneListRow.self], tableView: tableView)
        handler.viewModel = viewModel.tableViewModel()
        updateNoResults()
        loadAndShowData()
    }

    // MARK: Helper methods
    /// If no data exists in DB, make an API call to fetch and save the data, then display
    /// otherwise fetch data from DB and display
    private func loadAndShowData() {
        let allTimezones = self.viewModel.loadDataFromDB()
        if allTimezones.count == 0 {
            self.loadDataFromAPIAndSaveToDB()
        } else {
            self.viewModel = .ready(allTimezones, self.initialTimeZone, self.initialManualOffset, self.action)
        }
    }

    /// Helper method to call API and save the data to DB
    private func loadDataFromAPIAndSaveToDB() {
        let api = ServiceRemoteWordPressComREST.anonymousWordPressComRestApi(withUserAgent: WPUserAgent.wordPress())!
        let remoteService = BlogServiceRemoteREST(wordPressComRestApi: api, siteID: NSNumber(value: 0))
        remoteService.fetchTimeZoneList(success: { [weak self] (resultsDict) in
            self?.viewModel.insertDataToDB(resultsDict: resultsDict)
            self?.loadAndShowData()
            }, failure: { (error) in
                DDLogError("Error loading timezones: \(error)")
                self.viewModel = .error(String(describing: error))
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
