import UIKit
import NotificationCenter
import WordPressKit
import WordPressUI

class ThisWeekViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet private var tableView: UITableView!

    private var siteUrl: String = Constants.noDataLabel
    private var statsValues: ThisWeekWidgetStats?
    private var siteID: NSNumber?
    private var timeZone: TimeZone?
    private var oauthToken: String?
    private let tracks = Tracks(appGroupName: WPAppGroupName)

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
        let rowDifference = abs(updatedRowCount - tableView.visibleCells.count)

        // If the number of rows has not changed, do nothing.
        guard rowDifference != 0,
        let statsValues = statsValues else {
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.tableView.performBatchUpdates({
                // Create IndexPaths for rows to be inserted / deleted.
                let indexRange = (Constants.minRows..<statsValues.days.endIndex)
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

            DispatchQueue.main.async {
                self.tableView.reloadData()
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

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard showFooter(),
            let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: WidgetFooterView.reuseIdentifier) as? WidgetFooterView else {
                return nil
        }


        footer.configure(siteUrl: siteUrl)
        footer.frame.size.height = Constants.footerHeight
        return footer
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if !showFooter() {
            return 0
        }

        return Constants.footerHeight
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

            DispatchQueue.main.async {
                let summaryData = summary?.summaryData.reversed() ?? []
                self.statsValues = ThisWeekWidgetStats(days: ThisWeekWidgetStats.daysFrom(summaryData: summaryData))
                self.tableView.reloadData()
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

        let footerNib = UINib(nibName: String(describing: WidgetFooterView.self), bundle: Bundle(for: WidgetFooterView.self))
        tableView.register(footerNib, forHeaderFooterViewReuseIdentifier: WidgetFooterView.reuseIdentifier)
    }

    func unconfiguredCellFor(indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WidgetUnconfiguredCell.reuseIdentifier, for: indexPath) as? WidgetUnconfiguredCell else {
            return UITableViewCell()
        }

        cell.configure(for: .thisWeek)
        return cell
    }

    func statCellFor(indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WidgetDifferenceCell.reuseIdentifier, for: indexPath) as? WidgetDifferenceCell else {
            return UITableViewCell()
        }

        guard let statsValues = statsValues,
            indexPath.row < statsValues.days.endIndex else {
            cell.configure()
            return cell
        }

        cell.configure(day: statsValues.days[indexPath.row],
                       isToday: indexPath.row == 0,
                       hideSeparator: indexPath.row == (numberOfRowsToDisplay() - 1))

        return cell
    }

    func showFooter() -> Bool {
        return (extensionContext?.widgetActiveDisplayMode == .expanded && isConfigured && haveSiteUrl)
    }

    // MARK: - Expand / Compact View Helpers

    func numberOfRowsToDisplay() -> Int {
        if !isConfigured || extensionContext?.widgetActiveDisplayMode == .compact {
            return Constants.minRows
        }

        return statsValues?.days.count ?? Constants.minRows
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

        if showFooter() {
            height += tableView.footerView(forSection: 0)?.frame.height ?? Constants.footerHeight
        }

        let rowHeight = tableView.rectForRow(at: IndexPath(row: 0, section: 0)).height
        print("🔴 rowHeight: ", rowHeight)
        height += (rowHeight * CGFloat(numberOfRowsToDisplay()))

        return height
    }

    // MARK: - Constants

    enum Constants {
        static let noDataLabel = "-"
        static let minRows: Int = 2
        static let footerHeight: CGFloat = 32
    }

}

private extension Date {
    func convert(from timeZone: TimeZone, comparedWith target: TimeZone = TimeZone.current) -> Date {
        let delta = TimeInterval(timeZone.secondsFromGMT(for: self) - target.secondsFromGMT(for: self))
        return addingTimeInterval(delta)
    }
}
