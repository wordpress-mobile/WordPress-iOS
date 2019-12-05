import UIKit
import NotificationCenter
import WordPressKit
import WordPressUI

class AllTimeViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet private var tableView: UITableView!

    private var statsValues: AllTimeWidgetStats? {
        didSet {
            updateStatsLabels()
        }
    }

    private var visitorCount: String = Constants.noDataLabel
    private var viewCount: String = Constants.noDataLabel
    private var postCount: String = Constants.noDataLabel
    private var bestCount: String = Constants.noDataLabel
    private var siteUrl: String = Constants.noDataLabel
    private var footerHeight: CGFloat = 35

    private var haveSiteUrl: Bool {
        siteUrl != Constants.noDataLabel
    }

    private var siteID: NSNumber?
    private var timeZone: TimeZone?
    private var oauthToken: String?

    // TODO: handle expandy
    private var isConfigured = false

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveData()
    }

}

// MARK: - Widget Updating

extension AllTimeViewController: NCWidgetProviding {

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        retrieveSiteConfiguration()

        if !isConfigured {
            DDLogError("All Time Widget: Missing site ID, timeZone or oauth2Token")

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
    }

}

// MARK: - Table View Methods

extension AllTimeViewController: UITableViewDelegate, UITableViewDataSource {

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
        guard haveSiteUrl,
            isConfigured,
            let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: WidgetFooterView.reuseIdentifier) as? WidgetFooterView else {
                return nil
        }

        footer.configure(siteUrl: siteUrl)
        footerHeight = footer.frame.height

        return footer
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if !isConfigured || !haveSiteUrl {
            return 0
        }

        return footerHeight
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

private extension AllTimeViewController {

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

        statsRemote.getInsight { (allTimesStats: StatsAllTimesInsight?, error) in
            if error != nil {
                DDLogError("All Time Widget: Error fetching StatsAllTimesInsight: \(String(describing: error?.localizedDescription))")
                completionHandler(NCUpdateResult.failed)
                return
            }

            DDLogDebug("All Time Widget: Fetched StatsAllTimesInsight data.")

            DispatchQueue.main.async {
                self.statsValues = AllTimeWidgetStats(views: allTimesStats?.viewsCount,
                                            visitors: allTimesStats?.visitorsCount,
                                            posts: allTimesStats?.postsCount,
                                            bestViews: allTimesStats?.bestViewsPerDayCount)
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

        let footerNib = UINib(nibName: String(describing: WidgetFooterView.self), bundle: Bundle(for: WidgetFooterView.self))
        tableView.register(footerNib, forHeaderFooterViewReuseIdentifier: WidgetFooterView.reuseIdentifier)
    }

    func unconfiguredCellFor(indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WidgetUnconfiguredCell.reuseIdentifier, for: indexPath) as? WidgetUnconfiguredCell else {
            return UITableViewCell()
        }

        return cell
    }

    func statCellFor(indexPath: IndexPath) -> UITableViewCell {
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

    // MARK: - Expand / Compact View Helpers

    func numberOfRowsToDisplay() -> Int {
        if !isConfigured || extensionContext?.widgetActiveDisplayMode == .compact {
            return Constants.minRows
        }

        return Constants.maxRows
    }

    // MARK: - Helpers

    func displayString(for value: Int) -> String {
        return numberFormatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    func updateStatsLabels() {
        viewCount = displayString(for: statsValues?.views ?? 0)
        visitorCount = displayString(for: statsValues?.visitors ?? 0)
        postCount = displayString(for: statsValues?.posts ?? 0)
        bestCount = displayString(for: statsValues?.bestViews ?? 0)
    }

    // MARK: - Constants

    enum LocalizedText {
        static let visitors = NSLocalizedString("Visitors", comment: "Stats Visitors Label")
        static let views = NSLocalizedString("Views", comment: "Stats Views Label")
        static let posts = NSLocalizedString("Posts", comment: "Stats Posts Label")
        static let bestViews = NSLocalizedString("Best Views Ever", comment: "Stats 'Best Views Ever' Label")
    }

    enum Constants {
        static let noDataLabel = "-"
        static let minRows: Int = 1
        static let maxRows: Int = 2
    }

}
