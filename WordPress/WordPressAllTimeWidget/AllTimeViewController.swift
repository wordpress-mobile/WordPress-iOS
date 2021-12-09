import UIKit
import NotificationCenter
import WordPressKit
import WordPressUI
import Reachability

class AllTimeViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet private var tableView: UITableView!

    private var statsValues: AllTimeWidgetStats? {
        didSet {
            updateStatsLabels()
            tableView.reloadData()
        }
    }

    private var visitorCount: String = Constants.noDataLabel
    private var viewCount: String = Constants.noDataLabel
    private var postCount: String = Constants.noDataLabel
    private var bestCount: String = Constants.noDataLabel
    private var siteUrl: String = Constants.noDataLabel

    private var haveSiteUrl: Bool {
        siteUrl != Constants.noDataLabel
    }

    private var siteID: NSNumber?
    private var timeZone: TimeZone?
    private var oauthToken: String?

    private var isConfigured = false {
        didSet {
            setAvailableDisplayMode()
        }
    }

    private var isReachable = true {
        didSet {
            setAvailableDisplayMode()

            if isReachable != oldValue,
                let completionHandler = widgetCompletionBlock {
                widgetPerformUpdate(completionHandler: completionHandler)
            }
        }
    }

    private var showNoConnection: Bool {
        return !isReachable && statsValues == nil
    }

    private var loadingFailed = false {
        didSet {
            setAvailableDisplayMode()

            if loadingFailed != oldValue {
                tableView.reloadData()
            }
        }
    }

    private var failedState: Bool {
        return !isConfigured || showNoConnection || loadingFailed
    }

    private let tracks = Tracks(appGroupName: WPAppGroupName)
    private let reachability: Reachability = .forInternetConnection()

    private typealias WidgetCompletionBlock = (NCUpdateResult) -> Void
    private var widgetCompletionBlock: WidgetCompletionBlock?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        retrieveSiteConfiguration()
        registerTableCells()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSavedData()
        setupReachability()
        resizeView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reachability.stopNotifier()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let updatedRowCount = numberOfRowsToDisplay()

        // If the number of rows has not changed, do nothing.
        guard updatedRowCount != tableView.numberOfRows(inSection: 0) else {
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.tableView.performBatchUpdates({

                var indexPathsToInsert = [IndexPath]()
                var indexPathsToDelete = [IndexPath]()

                // If no connection was displayed, then rows are just being added.
                // Otherwise, a data row is being inserted/deleted.
                if self.tableView.visibleCells.first is WidgetNoConnectionCell {
                    let indexRange = (1..<updatedRowCount)
                    let indexPaths = indexRange.map({ return IndexPath(row: $0, section: 0) })
                    indexPathsToInsert.append(contentsOf: indexPaths)
                } else {
                    let lastDataRowIndexPath = IndexPath(row: 1, section: 0)
                    indexPathsToInsert.append(lastDataRowIndexPath)
                    indexPathsToDelete.append(lastDataRowIndexPath)
                }

                updatedRowCount > self.minRowsToDisplay() ?
                    self.tableView.insertRows(at: indexPathsToInsert, with: .fade) :
                    self.tableView.deleteRows(at: indexPathsToDelete, with: .fade)
            })
        })
    }

}

// MARK: - Widget Updating

extension AllTimeViewController: NCWidgetProviding {

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        widgetCompletionBlock = completionHandler
        retrieveSiteConfiguration()
        isReachable = reachability.isReachable()

        if !isConfigured || !isReachable {
            DDLogError("All Time Widget: unable to update. Configured: \(isConfigured) Reachable: \(isReachable)")

            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }

            completionHandler(.failed)
            return
        }

        fetchData(completionHandler: completionHandler)
    }

    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        tracks.trackDisplayModeChanged(properties: ["expanded": activeDisplayMode == .expanded])
        resizeView(withMaximumSize: maxSize)
    }

}

// MARK: - Table View Methods

extension AllTimeViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsToDisplay()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showNoConnection {
            return noConnectionCellFor(indexPath: indexPath)
        }

        if !isConfigured || loadingFailed {
            return unconfiguredCellFor(indexPath: indexPath)
        }

        return statCellFor(indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        if failedState,
            let maxCompactSize = extensionContext?.widgetMaximumSize(for: .compact) {
            // Use the max compact height for unconfigured view.
            return maxCompactSize.height
        }

        if showUrl() && indexPath.row == numberOfRowsToDisplay() - 1 {
            return WidgetUrlCell.height
        }

        return UITableView.automaticDimension
    }

}

// MARK: - Private Extension

private extension AllTimeViewController {

    // MARK: - Tap Gesture Handling

    @IBAction func handleTapGesture() {

        // If showing the loading failed view, reload the widget.
        if loadingFailed,
            let completionHandler = widgetCompletionBlock {
            widgetPerformUpdate(completionHandler: completionHandler)
            return
        }

        // Otherwise, open the app.
        guard isReachable,
            let extensionContext = extensionContext,
            let containingAppURL = appURL() else {
                DDLogError("All Time Widget: Unable to get extensionContext or appURL.")
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
            DDLogError("All Time Widget: Unable to get sharedDefaults.")
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
        statsValues = AllTimeWidgetStats.loadSavedData()
    }

    func saveData() {
        statsValues?.saveData()
    }

    func fetchData(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        guard let statsRemote = statsRemote() else {
            return
        }

        statsRemote.getInsight { [weak self] (allTimesStats: StatsAllTimesInsight?, error) in
            self?.loadingFailed = (error != nil)

            if error != nil {
                DDLogError("All Time Widget: Error fetching StatsAllTimesInsight: \(String(describing: error?.localizedDescription))")
                completionHandler(.failed)
                return
            }

            DDLogDebug("All Time Widget: Fetched StatsAllTimesInsight data.")

            DispatchQueue.main.async { [weak self] in
                let updatedStats = AllTimeWidgetStats(views: allTimesStats?.viewsCount,
                                                      visitors: allTimesStats?.visitorsCount,
                                                      posts: allTimesStats?.postsCount,
                                                      bestViews: allTimesStats?.bestViewsPerDayCount)

                // Update the widget only if the data has changed.
                guard updatedStats != self?.statsValues else {
                    completionHandler(.noData)
                    return
                }

                self?.statsValues = updatedStats
                completionHandler(.newData)
                self?.saveData()
            }
        }
    }

    func statsRemote() -> StatsServiceRemoteV2? {
        guard
            let siteID = siteID,
            let timeZone = timeZone,
            let oauthToken = oauthToken
            else {
                DDLogError("All Time Widget: Missing site ID, timeZone or oauth2Token")
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

        let noConnectionCellNib = UINib(nibName: String(describing: WidgetNoConnectionCell.self), bundle: Bundle(for: WidgetNoConnectionCell.self))
        tableView.register(noConnectionCellNib, forCellReuseIdentifier: WidgetNoConnectionCell.reuseIdentifier)
    }

    func noConnectionCellFor(indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WidgetNoConnectionCell.reuseIdentifier, for: indexPath) as? WidgetNoConnectionCell else {
            return UITableViewCell()
        }

        return cell
    }

    func unconfiguredCellFor(indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WidgetUnconfiguredCell.reuseIdentifier, for: indexPath) as? WidgetUnconfiguredCell else {
            return UITableViewCell()
        }

        loadingFailed ? cell.configure(for: .loadingFailed) : cell.configure(for: .allTime)
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
            cell.configure(leftItemName: LocalizedText.posts,
                           leftItemData: postCount,
                           rightItemName: LocalizedText.bestViews,
                           rightItemData: bestCount)
        }

        return cell
    }

    func showUrl() -> Bool {
        return (isConfigured && haveSiteUrl)
    }

    // MARK: - Expand / Compact View Helpers

    func setAvailableDisplayMode() {
        // If something went wrong, don't allow the widget to be expanded.
        extensionContext?.widgetLargestAvailableDisplayMode = failedState ? .compact : .expanded
    }

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
        let dataRowHeight: CGFloat

        // This method is called before the rows are updated.
        // So if a no connection cell was displayed, use the default height for data rows.
        // Otherwise, use the actual height from the first data row.
        if tableView.visibleCells.first is WidgetNoConnectionCell {
            dataRowHeight = WidgetTwoColumnCell.defaultHeight
        } else {
            dataRowHeight = tableView.rectForRow(at: IndexPath(row: 0, section: 0)).height
        }

        let numRows = numberOfRowsToDisplay()

        if showUrl() {
            height += WidgetUrlCell.height
            height += (dataRowHeight * CGFloat(numRows - 1))
        } else {
            height += (dataRowHeight * CGFloat(numRows))
        }

        return height
    }
    // MARK: - Reachability

    func setupReachability() {
        isReachable = reachability.isReachable()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reachabilityChanged),
                                               name: NSNotification.Name.reachabilityChanged,
                                               object: nil)
        reachability.startNotifier()
    }

    @objc func reachabilityChanged() {
        isReachable = reachability.isReachable()
    }

    // MARK: - Helpers

    func updateStatsLabels() {
        guard let values = statsValues else {
            return
        }

        viewCount = values.views.abbreviatedString()
        visitorCount = values.visitors.abbreviatedString()
        postCount = values.posts.abbreviatedString()
        bestCount = values.bestViews.abbreviatedString()
    }

    // MARK: - Constants

    enum LocalizedText {
        static let visitors = AppLocalizedString("Visitors", comment: "Stats Visitors Label")
        static let views = AppLocalizedString("Views", comment: "Stats Views Label")
        static let posts = AppLocalizedString("Posts", comment: "Stats Posts Label")
        static let bestViews = AppLocalizedString("Best views ever", comment: "Stats 'Best views ever' Label")
    }

    enum Constants {
        static let noDataLabel = "-"
        static let baseUrl: String = "\(WPComScheme)://"
        static let statsUrl: String = Constants.baseUrl + "viewstats?siteId="
    }

}
