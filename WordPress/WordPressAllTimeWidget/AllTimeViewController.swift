import UIKit
import NotificationCenter
import WordPressKit

class AllTimeViewController: UIViewController {

    // MARK: - Properties

    // TODO: For testing only. Remove when table added.
    @IBOutlet private var visitors: UILabel!
    @IBOutlet private var views: UILabel!
    @IBOutlet private var posts: UILabel!
    @IBOutlet private var best: UILabel!
    @IBOutlet private var url: UILabel!
    ////

    private var statsValues: AllTimeWidgetStats? {
        didSet {
            updateStatsLabels()
        }
    }

    private var siteUrl: String = Constants.noDataLabel

    private var siteID: NSNumber?
    private var timeZone: TimeZone?
    private var oauthToken: String?
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
                // TODO: reload table here
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

                // TODO: reload table here
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

    // MARK: - Helpers

    func displayString(for value: Int) -> String {
        return numberFormatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    func updateStatsLabels() {
        views.text = displayString(for: statsValues?.views ?? 0)
        visitors.text = displayString(for: statsValues?.visitors ?? 0)
        posts.text = displayString(for: statsValues?.posts ?? 0)
        best.text = displayString(for: statsValues?.bestViews ?? 0)
        url.text = siteUrl
    }

    // MARK: - Constants

    enum Constants {
        static let noDataLabel = "-"
    }

}
