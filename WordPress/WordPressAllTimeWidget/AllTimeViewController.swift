import UIKit
import NotificationCenter
import WordPressKit

class AllTimeViewController: UIViewController {

    // MARK: - Properties

    private var statsValues: AllTimeWidgetStats?

    private var siteID: NSNumber?
    private var timeZone: TimeZone?
    private var oauthToken: String?

    private let tracks = Tracks(appGroupName: WPAppGroupName)

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
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
        tracks.trackExtensionAccessed()
        completionHandler(NCUpdateResult.newData)
    }

    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        tracks.trackDisplayModeChanged(properties: ["expanded": activeDisplayMode == .expanded])
    }

}

// MARK: - Private Extension

private extension AllTimeViewController {

    // MARK: - Data Management

    func loadSavedData() {
        statsValues = AllTimeWidgetStats.loadSavedData()
    }

    func saveData() {
        statsValues?.saveData()
    }

    func fetchData() {
        guard let statsRemote = statsRemote() else {
            return
        }

        statsRemote.getInsight { (allTimesStats: StatsAllTimesInsight?, error) in
            if error != nil {
                DDLogError("All Time Widget: Error fetching StatsAllTimesInsight: \(String(describing: error?.localizedDescription))")
                return
            }

            DDLogDebug("All Time Widget: Fetched StatsAllTimesInsight data.")

            DispatchQueue.main.async {
                self.statsValues = AllTimeWidgetStats(views: allTimesStats?.viewsCount ?? 0,
                                            visitors: allTimesStats?.visitorsCount ?? 0,
                                            posts: allTimesStats?.postsCount ?? 0,
                                            bestViews: allTimesStats?.bestViewsPerDayCount ?? 0)

                // TODO: - reload table here
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

}
