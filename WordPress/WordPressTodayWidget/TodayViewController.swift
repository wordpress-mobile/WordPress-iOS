import UIKit
import NotificationCenter
import CocoaLumberjack
import WordPressComStatsiOS
import WordPressShared

class TodayViewController: UIViewController {
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

    var siteID: NSNumber?
    var timeZone: TimeZone?
    var oauthToken: String?
    var siteName: String = ""
    var visitorCount: String = ""
    var viewCount: String = ""
    var isConfigured = false
    var tracks = Tracks(appGroupName: WPAppGroupName)

    override func viewDidLoad() {
        super.viewDidLoad()

        let backgroundImage = UIImage(color: WPStyleGuide.wordPressBlue()).resizableImage(withCapInsets: UIEdgeInsets.zero)

        configureMeLabel.text = NSLocalizedString("Display your site stats for today here. Configure in the WordPress app under your site > Stats > Today.", comment: "Unconfigured stats today widget helper text")
        configureMeButton.setTitle(NSLocalizedString("Open WordPress", comment: "Today widget button to launch WP app"), for: UIControlState())
        configureMeButton.setBackgroundImage(backgroundImage, for: UIControlState())
        configureMeButton.clipsToBounds = true
        configureMeButton.layer.cornerRadius = 5.0

        siteNameLabel.text = "-"
        visitorsLabel.text = NSLocalizedString("Visitors", comment: "Stats Visitors Label")
        visitorsCountLabel.text = "-"
        viewsLabel.text = NSLocalizedString("Views", comment: "Stats Views Label")
        viewsCountLabel.text = "-"

        changeTextColor()

        retrieveSiteConfiguration()
        updateUIBasedOnWidgetConfiguration()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Manual state restoration
        let sharedDefaults = UserDefaults(suiteName: WPAppGroupName)!
        siteName = sharedDefaults.string(forKey: WPStatsTodayWidgetUserDefaultsSiteNameKey) ?? ""

        let userDefaults = UserDefaults.standard
        visitorCount = userDefaults.string(forKey: WPStatsTodayWidgetUserDefaultsVisitorCountKey) ?? "0"
        viewCount = userDefaults.string(forKey: WPStatsTodayWidgetUserDefaultsViewCountKey) ?? "0"

        siteNameLabel.text = siteName
        visitorsCountLabel.text = visitorCount
        viewsCountLabel.text = viewCount

        retrieveSiteConfiguration()
        updateUIBasedOnWidgetConfiguration()
    }

    func changeTextColor() {
        configureMeLabel.textColor = UIColor.black
        siteNameLabel.textColor = UIColor.black
        visitorsCountLabel.textColor = UIColor.black
        viewsCountLabel.textColor = UIColor.black
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Manual state restoration
        let userDefaults = UserDefaults.standard
        userDefaults.set(visitorCount, forKey: WPStatsTodayWidgetUserDefaultsVisitorCountKey)
        userDefaults.set(viewCount, forKey: WPStatsTodayWidgetUserDefaultsViewCountKey)
    }

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
}

extension TodayViewController: NCWidgetProviding {
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        retrieveSiteConfiguration()
        DispatchQueue.main.async {
            self.updateUIBasedOnWidgetConfiguration()
        }

        if isConfigured == false {
            DDLogError("Missing site ID, timeZone or oauth2Token")

            completionHandler(NCUpdateResult.failed)
            return
        }

        tracks.trackExtensionAccessed()

        let statsService: WPStatsService = WPStatsService(siteId: siteID, siteTimeZone: timeZone, oauth2Token: oauthToken, andCacheExpirationInterval: 0)
        statsService.retrieveTodayStats(completionHandler: { wpStatsSummary, error in
            DDLogInfo("Downloaded data in the Today widget")

            DispatchQueue.main.async {
                self.visitorCount = (wpStatsSummary?.visitors)!
                self.viewCount = (wpStatsSummary?.views)!

                self.siteNameLabel?.text = self.siteName
                self.visitorsCountLabel?.text = self.visitorCount
                self.viewsCountLabel?.text = self.viewCount
            }
            completionHandler(NCUpdateResult.newData)
            }, failureHandler: { error in
                DDLogError("\(String(describing: error))")

                if let error = error as? URLError, error.code == URLError.badServerResponse {
                    self.isConfigured = false
                    self.updateUIBasedOnWidgetConfiguration()
                }

                completionHandler(NCUpdateResult.failed)
        })
    }
}
