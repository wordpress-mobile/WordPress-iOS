import UIKit
import NotificationCenter
import CocoaLumberjack
import WordPressKit
import WordPressUI

class TodayViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet private var tableView: UITableView!

    private var statsValues: TodayWidgetStats? {
        didSet {
            updateStatsLabels()
            tableView.reloadData()
        }
    }

    private var visitorCount: String = Constants.noDataLabel
    private var viewCount: String = Constants.noDataLabel
    private var likeCount: String = Constants.noDataLabel
    private var commentCount: String = Constants.noDataLabel
    private var siteUrl: String = Constants.noDataLabel

    private var haveSiteUrl: Bool {
        siteUrl != Constants.noDataLabel
    }

    private var siteID: NSNumber?
    private var timeZone: TimeZone?
    private var oauthToken: String?
    private var isConfigured = false {
        didSet {
            // If unconfigured, don't allow the widget to be expanded/compacted.
            extensionContext?.widgetLargestAvailableDisplayMode = isConfigured ? .expanded : .compact
        }
    }

    private let tracks = Tracks(appGroupName: WPAppGroupName)

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

        // If the number of rows has not changed, do nothing.
        guard updatedRowCount != tableView.visibleCells.count else {
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.tableView.performBatchUpdates({
                let lastDataRowIndexPath = [IndexPath(row: 1, section: 0)]
                updatedRowCount > self.minRowsToDisplay() ?
                    self.tableView.insertRows(at: lastDataRowIndexPath, with: .fade) :
                    self.tableView.deleteRows(at: lastDataRowIndexPath, with: .fade)
            })
        })
    }

}

// MARK: - Widget Updating

extension TodayViewController: NCWidgetProviding {

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        retrieveSiteConfiguration()

        if !isConfigured {
            DDLogError("Today Widget: Missing site ID, timeZone or oauth2Token")

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

extension TodayViewController: UITableViewDelegate, UITableViewDataSource {

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

        if showUrl() && indexPath.row == numberOfRowsToDisplay() - 1 {
            return WidgetUrlCell.height
        }

        guard !isConfigured,
            let maxCompactSize = extensionContext?.widgetMaximumSize(for: .compact) else {
                return UITableView.automaticDimension
        }

        // Use the max compact height for unconfigured view.
        return maxCompactSize.height
    }

}

// MARK: - Private Extension

private extension TodayViewController {

    // MARK: - Launch Containing App

    @IBAction func launchContainingApp() {
        guard let extensionContext = extensionContext,
            let containingAppURL = appURL() else {
                DDLogError("Today Widget: Unable to get extensionContext or appURL.")
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
            DDLogError("Today Widget: Unable to get sharedDefaults.")
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
        statsValues = TodayWidgetStats.loadSavedData()
    }

    func saveData() {
        statsValues?.saveData()
    }

    func fetchData(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        guard let statsRemote = statsRemote() else {
            return
        }

        statsRemote.getInsight { (todayInsight: StatsTodayInsight?, error) in
            if error != nil {
                DDLogError("Today Widget: Error fetching StatsTodayInsight: \(String(describing: error?.localizedDescription))")
                completionHandler(NCUpdateResult.failed)
                return
            }

            DDLogDebug("Today Widget: Fetched StatsTodayInsight data.")

            DispatchQueue.main.async { [weak self] in
                self?.statsValues = TodayWidgetStats(views: todayInsight?.viewsCount,
                                                    visitors: todayInsight?.visitorsCount,
                                                    likes: todayInsight?.likesCount,
                                                    comments: todayInsight?.commentsCount)
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
                DDLogError("Today Widget: Missing site ID, timeZone or oauth2Token")
                return nil
        }

        let wpApi = WordPressComRestApi(oAuthToken: oauthToken)
        return StatsServiceRemoteV2(wordPressComRestApi: wpApi, siteID: siteID.intValue, siteTimezone: timeZone)
    }

    // MARK: - Table Helpers

    func registerTableCells() {
        let twoColumnCellNib = UINib(nibName: String(describing: WidgetTwoColumnCell.self), bundle: Bundle(for: WidgetTwoColumnCell.self))
        tableView.register(twoColumnCellNib, forCellReuseIdentifier: WidgetTwoColumnCell.reuseIdentifier)

        let unconfiguredCellNib = UINib(nibName: String(describing: WidgetUnconfiguredCell.self), bundle: Bundle(for: WidgetUnconfiguredCell.self))
        tableView.register(unconfiguredCellNib, forCellReuseIdentifier: WidgetUnconfiguredCell.reuseIdentifier)

        let urlCellNib = UINib(nibName: String(describing: WidgetUrlCell.self), bundle: Bundle(for: WidgetUrlCell.self))
        tableView.register(urlCellNib, forCellReuseIdentifier: WidgetUrlCell.reuseIdentifier)
    }

    func unconfiguredCellFor(indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WidgetUnconfiguredCell.reuseIdentifier, for: indexPath) as? WidgetUnconfiguredCell else {
            return UITableViewCell()
        }

        cell.configure(for: .today)
        return cell
    }

    func statCellFor(indexPath: IndexPath) -> UITableViewCell {

        // URL Cell
        if showUrl() && indexPath.row == numberOfRowsToDisplay() - 1 {
            guard let urlCell = tableView.dequeueReusableCell(withIdentifier: WidgetUrlCell.reuseIdentifier, for: indexPath) as? WidgetUrlCell else {
                return UITableViewCell()
            }

            urlCell.configure(siteUrl: siteUrl)
            return urlCell
        }

        // Data Cells
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WidgetTwoColumnCell.reuseIdentifier, for: indexPath) as? WidgetTwoColumnCell else {
            return UITableViewCell()
        }

        if indexPath.row == 0 {
            cell.configure(leftItemName: LocalizedText.views,
                           leftItemData: viewCount,
                           rightItemName: LocalizedText.visitors,
                           rightItemData: visitorCount)
        } else {
            cell.configure(leftItemName: LocalizedText.likes,
                           leftItemData: likeCount,
                           rightItemName: LocalizedText.comments,
                           rightItemData: commentCount)
        }

        return cell
    }

    func showUrl() -> Bool {
        return (isConfigured && haveSiteUrl)
    }

    // MARK: - Expand / Compact View Helpers

    func minRowsToDisplay() -> Int {
        return showUrl() ? 2 : 1
    }

    func maxRowsToDisplay() -> Int {
        return showUrl() ? 3 : 2
    }

    func numberOfRowsToDisplay() -> Int {
        return extensionContext?.widgetActiveDisplayMode == .compact ? minRowsToDisplay() : maxRowsToDisplay()
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
        let dataRowHeight = tableView.rectForRow(at: IndexPath(row: 0, section: 0)).height
        let numRows = numberOfRowsToDisplay()

        if showUrl() {
            height += WidgetUrlCell.height
            height += (dataRowHeight * CGFloat(numRows - 1))
        } else {
            height += (dataRowHeight * CGFloat(numRows))
        }

        return height
    }

    // MARK: - Helpers

    func updateStatsLabels() {
        guard let values = statsValues else {
            return
        }

        viewCount = values.views.abbreviatedString()
        visitorCount = values.visitors.abbreviatedString()
        likeCount = values.likes.abbreviatedString()
        commentCount = values.comments.abbreviatedString()
    }

    // MARK: - Constants

    enum LocalizedText {
        static let visitors = NSLocalizedString("Visitors", comment: "Stats Visitors Label")
        static let views = NSLocalizedString("Views", comment: "Stats Views Label")
        static let likes = NSLocalizedString("Likes", comment: "Stats Likes Label")
        static let comments = NSLocalizedString("Comments", comment: "Stats Comments Label")
    }

    enum Constants {
        static let noDataLabel = "-"
        static let baseUrl: String = "\(WPComScheme)://"
        static let statsUrl: String = Constants.baseUrl + "viewstats?siteId="
    }

}
