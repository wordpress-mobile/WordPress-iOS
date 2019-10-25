import UIKit
import NotificationCenter
import CocoaLumberjack
import WordPressKit
import WordPressUI

class TodayViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet var unconfiguredView: UIStackView!
    @IBOutlet var configureMeLabel: UILabel!
    @IBOutlet var siteNameLabel: UILabel!
    @IBOutlet var configuredView: UIStackView!
    @IBOutlet var countContainerView: UIView!
    @IBOutlet var visitorsCountLabel: UILabel!
    @IBOutlet var visitorsLabel: UILabel!
    @IBOutlet var viewsCountLabel: UILabel!
    @IBOutlet var viewsLabel: UILabel!
    @IBOutlet var configureMeButton: UIButton!

    private var siteID: NSNumber?
    private var timeZone: TimeZone?
    private var oauthToken: String?
    private var siteName: String = ""
    private var visitorCount: Int = 0
    private var viewCount: Int = 0
    private var isConfigured = false
    private let tracks = Tracks(appGroupName: WPAppGroupName)

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        let labelText = NSLocalizedString("Display your site stats for today here. Configure in the WordPress app " +
            "under your site > Stats > Today.", comment: "Unconfigured stats today widget helper text")
        configureMeLabel.text = labelText

        let buttonText = NSLocalizedString("Open WordPress", comment: "Today widget button to launch WP app")
        configureMeButton.setTitle(buttonText, for: .normal)
        configureMeButton.backgroundColor = .primary
        configureMeButton.clipsToBounds = true
        configureMeButton.layer.cornerRadius = 5.0

        siteNameLabel.text = "-"
        visitorsLabel.text = NSLocalizedString("Visitors", comment: "Stats Visitors Label")
        visitorsCountLabel.text = "-"
        viewsLabel.text = NSLocalizedString("Views", comment: "Stats Views Label")
        viewsCountLabel.text = "-"

        changeTextColor()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadSavedData()
        updateLabels()
        retrieveSiteConfiguration()
        updateUIBasedOnWidgetConfiguration()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        TodayWidgetStats.saveData(views: viewCount, visitors: visitorCount)
    }

}

// MARK: - Widget Updating

extension TodayViewController: NCWidgetProviding {
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        retrieveSiteConfiguration()

        DispatchQueue.main.async {
            self.updateUIBasedOnWidgetConfiguration()
        }

        if !isConfigured {
            DDLogError("Today Widget: Missing site ID, timeZone or oauth2Token")
            completionHandler(NCUpdateResult.failed)
            return
        }

        tracks.trackExtensionAccessed()

        guard let statsRemote = statsRemote() else {
            return
        }

        statsRemote.getInsight { (todayInsight: StatsTodayInsight?, error) in
            if error != nil {
                DDLogError("Today Widget: Error fetching StatsTodayInsight: \(String(describing: error?.localizedDescription))")
                return
            }

            DDLogDebug("Today Widget: Fetched StatsTodayInsight data.")

            DispatchQueue.main.async {
                self.visitorCount = todayInsight?.visitorsCount ?? 0
                self.viewCount = todayInsight?.viewsCount ?? 0
                self.updateLabels()
            }
        }
    }

}

// MARK: - Private Extension

private extension TodayViewController {

    @IBAction func launchContainingApp() {
        if let unwrappedSiteID = siteID {
            tracks.trackExtensionStatsLaunched(unwrappedSiteID.intValue)
            extensionContext!.open(URL(string: "\(WPComScheme)://viewstats?siteId=\(unwrappedSiteID)")!, completionHandler: nil)
        } else {
            tracks.trackExtensionConfigureLaunched()
            extensionContext!.open(URL(string: "\(WPComScheme)://")!, completionHandler: nil)
        }
    }

    func updateUIBasedOnWidgetConfiguration() {
        unconfiguredView.isHidden = isConfigured
        configuredView.isHidden = !isConfigured

        view.setNeedsUpdateConstraints()
    }

    func retrieveSiteConfiguration() {
        let sharedDefaults = UserDefaults(suiteName: WPAppGroupName)!
        siteID = sharedDefaults.object(forKey: WPStatsTodayWidgetUserDefaultsSiteIdKey) as? NSNumber
        siteName = sharedDefaults.string(forKey: WPStatsTodayWidgetUserDefaultsSiteNameKey) ?? ""
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

    func loadSavedData() {
        let data = TodayWidgetStats.loadSavedData()
        visitorCount = data.visitors
        viewCount = data.views
    }

    func updateLabels() {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        visitorsCountLabel.text = numberFormatter.string(from: NSNumber(value: visitorCount)) ?? "0"
        viewsCountLabel.text = numberFormatter.string(from: NSNumber(value: viewCount)) ?? "0"

        siteNameLabel.text = siteName
    }

    func changeTextColor() {
        configureMeLabel.textColor = .text
        siteNameLabel.textColor = .text
        visitorsCountLabel.textColor = .text
        viewsCountLabel.textColor = .text
        visitorsLabel.textColor = .textSubtle
        viewsLabel.textColor = .textSubtle
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

}
