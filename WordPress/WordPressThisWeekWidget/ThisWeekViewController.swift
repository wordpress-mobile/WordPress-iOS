import UIKit
import NotificationCenter
import WordPressKit
import WordPressUI

class ThisWeekViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet private var tableView: UITableView!

    private var siteUrl: String = Constants.noDataLabel
    private var siteID: NSNumber?
    private var timeZone: TimeZone?
    private var oauthToken: String?
    private let tracks = Tracks(appGroupName: WPAppGroupName)

    private var statsValues: ThisWeekWidgetStats? {
        didSet {
            tableView.reloadData()
        }
    }

    private var haveSiteUrl: Bool {
        siteUrl != Constants.noDataLabel
    }

    private var isConfigured = false {
        didSet {
            // If unconfigured, don't allow the widget to be expanded/compacted.
            extensionContext?.widgetLargestAvailableDisplayMode = isConfigured ? .expanded : .compact
        }
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        retrieveSiteConfiguration()
        registerTableCells()
        configureTableSeparator()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSavedData()
        resizeView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveData()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let updatedRowCount = numberOfRowsToDisplay()
        let rowDifference = abs(updatedRowCount - tableView.numberOfRows(inSection: 0))

        // If the number of rows has not changed, do nothing.
        guard rowDifference != 0 else {
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.tableView.performBatchUpdates({
                // Create IndexPaths for rows to be inserted / deleted.
                let indexRange = (Constants.minRows..<self.maxRowsToDisplay())
                let indexPaths = indexRange.map({ return IndexPath(row: $0, section: 0) })

                updatedRowCount > Constants.minRows ?
                    self.tableView.insertRows(at: indexPaths, with: .fade) :
                    self.tableView.deleteRows(at: indexPaths, with: .fade)
            })
        })
    }

}

// MARK: - Widget Updating

extension ThisWeekViewController: NCWidgetProviding {

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        retrieveSiteConfiguration()

        if !isConfigured {
            DDLogError("This Week Widget: Missing site ID, timeZone or oauth2Token")

            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }

            completionHandler(NCUpdateResult.failed)
            return
        }

        tracks.trackExtensionAccessed()
        fetchData(completionHandler: completionHandler)
    }

    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        tracks.trackDisplayModeChanged(properties: ["expanded": activeDisplayMode == .expanded])
        resizeView(withMaximumSize: maxSize)
    }

}

// MARK: - Table View Methods

extension ThisWeekViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsToDisplay()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard isConfigured else {
            return unconfiguredCellFor(indexPath: indexPath)
        }

        return statCellFor(indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard !isConfigured,
            let maxCompactSize = extensionContext?.widgetMaximumSize(for: .compact) else {
                return UITableView.automaticDimension
        }

        // Use the max compact height for unconfigured view.
        return maxCompactSize.height
    }

}

// MARK: - Private Extension

private extension ThisWeekViewController {

    // MARK: - Launch Containing App

    @IBAction func launchContainingApp() {
        guard let extensionContext = extensionContext,
            let containingAppURL = appURL() else {
                DDLogError("This Week Widget: Unable to get extensionContext or appURL.")
                return
        }

        trackAppLaunch()
        extensionContext.open(containingAppURL, completionHandler: nil)
    }

    func appURL() -> URL? {
        let urlString = (siteID != nil) ? (Constants.statsUrl + siteID!.stringValue) : Constants.baseUrl
        return URL(string: urlString)
    }

    func trackAppLaunch() {
        guard let siteID = siteID else {
            tracks.trackExtensionConfigureLaunched()
            return
        }

        tracks.trackExtensionStatsLaunched(siteID.intValue)
    }

    // MARK: - Site Configuration

    func retrieveSiteConfiguration() {
        guard let sharedDefaults = UserDefaults(suiteName: WPAppGroupName) else {
            DDLogError("This Week Widget: Unable to get sharedDefaults.")
            isConfigured = false
            return
        }

        siteID = sharedDefaults.object(forKey: WPStatsTodayWidgetUserDefaultsSiteIdKey) as? NSNumber
        siteUrl = sharedDefaults.string(forKey: WPStatsTodayWidgetUserDefaultsSiteUrlKey) ?? Constants.noDataLabel
        oauthToken = fetchOAuthBearerToken()

        if let timeZoneName = sharedDefaults.string(forKey: WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey) {
            timeZone = TimeZone(identifier: timeZoneName)
        }

        isConfigured = siteID != nil && timeZone != nil && oauthToken != nil
    }

    func fetchOAuthBearerToken() -> String? {
        let oauth2Token = try? SFHFKeychainUtils.getPasswordForUsername(WPStatsTodayWidgetKeychainTokenKey, andServiceName: WPStatsTodayWidgetKeychainServiceName, accessGroup: WPAppKeychainAccessGroup)

        return oauth2Token as String?
    }

    // MARK: - Data Management

    func loadSavedData() {
        statsValues = ThisWeekWidgetStats.loadSavedData()
    }

    func saveData() {
        statsValues?.saveData()
    }

    func fetchData(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        guard let statsRemote = statsRemote() else {
            return
        }

        // Get the current date in the site's time zone.
        let siteTimeZone = timeZone ?? .autoupdatingCurrent
        let weekEndingDate = Date().convert(from: siteTimeZone).normalizedDate()

        // Include an extra day. It's needed to get the dailyChange for the last day.
        statsRemote.getData(for: .day, endingOn: weekEndingDate, limit: ThisWeekWidgetStats.maxDaysToDisplay + 1) { [unowned self] (summary: StatsSummaryTimeIntervalData?, error: Error?) in
            if error != nil {
                DDLogError("This Week Widget: Error fetching summary: \(String(describing: error?.localizedDescription))")
                completionHandler(NCUpdateResult.failed)
                return
            }

            DDLogDebug("This Week Widget: Fetched summary data.")

            DispatchQueue.main.async { [weak self] in
                let summaryData = summary?.summaryData.reversed() ?? []
                self?.statsValues = ThisWeekWidgetStats(days: ThisWeekWidgetStats.daysFrom(summaryData: summaryData))
            }
            completionHandler(NCUpdateResult.newData)
        }
    }

    func statsRemote() -> StatsServiceRemoteV2? {
        guard
            let siteID = siteID,
            let timeZone = timeZone,
            let oauthToken = oauthToken
            else {
                DDLogError("This Week Widget: Missing site ID, timeZone or oauth2Token")
                return nil
        }

        let wpApi = WordPressComRestApi(oAuthToken: oauthToken)
        return StatsServiceRemoteV2(wordPressComRestApi: wpApi, siteID: siteID.intValue, siteTimezone: timeZone)
    }

    // MARK: - Table Helpers

    func registerTableCells() {
        let differenceCellNib = UINib(nibName: String(describing: WidgetDifferenceCell.self), bundle: Bundle(for: WidgetDifferenceCell.self))
        tableView.register(differenceCellNib, forCellReuseIdentifier: WidgetDifferenceCell.reuseIdentifier)

        let unconfiguredCellNib = UINib(nibName: String(describing: WidgetUnconfiguredCell.self), bundle: Bundle(for: WidgetUnconfiguredCell.self))
        tableView.register(unconfiguredCellNib, forCellReuseIdentifier: WidgetUnconfiguredCell.reuseIdentifier)

        let urlCellNib = UINib(nibName: String(describing: WidgetUrlCell.self), bundle: Bundle(for: WidgetUrlCell.self))
        tableView.register(urlCellNib, forCellReuseIdentifier: WidgetUrlCell.reuseIdentifier)
    }

    func configureTableSeparator() {
        tableView.separatorColor = WidgetStyles.separatorColor
        tableView.separatorEffect = WidgetStyles.separatorVibrancyEffect
    }

    func unconfiguredCellFor(indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WidgetUnconfiguredCell.reuseIdentifier, for: indexPath) as? WidgetUnconfiguredCell else {
            return UITableViewCell()
        }

        cell.configure(for: .thisWeek)
        return cell
    }

    func statCellFor(indexPath: IndexPath) -> UITableViewCell {

        // URL Cell
        if showUrl() && indexPath.row == numberOfRowsToDisplay() - 1 {
            guard let urlCell = tableView.dequeueReusableCell(withIdentifier: WidgetUrlCell.reuseIdentifier, for: indexPath) as? WidgetUrlCell else {
                return UITableViewCell()
            }

            urlCell.configure(siteUrl: siteUrl, hideSeparator: true)
            return urlCell
        }


        // Data Cells
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WidgetDifferenceCell.reuseIdentifier, for: indexPath) as? WidgetDifferenceCell else {
            return UITableViewCell()
        }

        guard let statsValues = statsValues,
            indexPath.row < statsValues.days.endIndex else {
            cell.configure()
            return cell
        }

        cell.configure(day: statsValues.days[indexPath.row], isToday: indexPath.row == 0)

        return cell
    }

    func showUrl() -> Bool {
        return (extensionContext?.widgetActiveDisplayMode == .expanded && isConfigured && haveSiteUrl)
    }

    // MARK: - Expand / Compact View Helpers

    func numberOfRowsToDisplay() -> Int {
        guard isConfigured,
            extensionContext?.widgetActiveDisplayMode == .expanded else {
                return Constants.minRows
        }
        return maxRowsToDisplay()
    }

    func maxRowsToDisplay() -> Int {
        guard let values = statsValues,
            !values.days.isEmpty else {
                // Add one for URL row
                return ThisWeekWidgetStats.maxDaysToDisplay + 1
        }

        // Add one for URL row
        return values.days.count + 1
    }

    func resizeView(withMaximumSize size: CGSize? = nil) {
        guard let maxSize = size ?? extensionContext?.widgetMaximumSize(for: .compact) else {
            return
        }

        let expanded = extensionContext?.widgetActiveDisplayMode == .expanded
        preferredContentSize = expanded ? CGSize(width: maxSize.width, height: expandedHeight()) : maxSize
    }

    func expandedHeight() -> CGFloat {
        var height: CGFloat = 0

        if showUrl() {
            height += WidgetUrlCell.height
        }

        let dataRowHeight = tableView.rectForRow(at: IndexPath(row: 0, section: 0)).height
        height += (dataRowHeight * CGFloat(numberOfRowsToDisplay() - 1))

        return height
    }

    // MARK: - Constants

    enum Constants {
        static let noDataLabel = "-"
        static let baseUrl: String = "\(WPComScheme)://"
        static let statsUrl: String = Constants.baseUrl + "viewstats?siteId="
        static let minRows: Int = 2
    }

}

private extension Date {
    func convert(from timeZone: TimeZone, comparedWith target: TimeZone = TimeZone.current) -> Date {
        let delta = TimeInterval(timeZone.secondsFromGMT(for: self) - target.secondsFromGMT(for: self))
        return addingTimeInterval(delta)
    }
}
