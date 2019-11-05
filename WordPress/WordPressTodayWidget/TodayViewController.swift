import UIKit
import NotificationCenter
import CocoaLumberjack
import WordPressKit
import WordPressUI

class TodayViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet private weak var unconfiguredView: UIStackView!
    @IBOutlet private weak var configureLabel: UILabel!
    @IBOutlet private weak var configureButton: UIButton!

    @IBOutlet private weak var configuredView: UIStackView!
    @IBOutlet private weak var rowsStackView: UIStackView!
    @IBOutlet private weak var separatorLine: UIView!
    @IBOutlet private weak var siteNameLabel: UILabel!
    @IBOutlet private weak var siteUrlLabel: UILabel!

    private var siteName: String = ""
    private var siteUrl: String = ""
    private var visitorCount: Int = 0
    private var viewCount: Int = 0
    private var likeCount: Int = 0
    private var commentCount: Int = 0

    private var siteID: NSNumber?
    private var timeZone: TimeZone?
    private var oauthToken: String?
    private var isConfigured = false

    private let tracks = Tracks(appGroupName: WPAppGroupName)

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        configureLabel.text = LocalizedText.configure
        configureButton.setTitle(LocalizedText.openWordPress, for: .normal)
        configureButton.backgroundColor = .primary
        configureButton.clipsToBounds = true
        configureButton.layer.cornerRadius = Constants.buttonCornerRadius

        siteNameLabel.text = Constants.noDataLabel
        siteUrlLabel.text = Constants.noDataLabel

        initRows()
        configureColors()
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
        TodayWidgetStats.saveData(views: viewCount, visitors: visitorCount, likes: likeCount, comments: commentCount)
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
                self.likeCount = todayInsight?.likesCount ?? 0
                self.commentCount = todayInsight?.commentsCount ?? 0
                self.updateLabels()
            }
        }
    }

}

// MARK: - Private Extension

private extension TodayViewController {

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

    func updateUIBasedOnWidgetConfiguration() {
        unconfiguredView.isHidden = isConfigured
        configuredView.isHidden = !isConfigured

        view.setNeedsUpdateConstraints()
    }

    func retrieveSiteConfiguration() {
        guard let sharedDefaults = UserDefaults(suiteName: WPAppGroupName) else {
            DDLogError("Today Widget: Unable to get sharedDefaults.")
            isConfigured = false
            return
        }

        siteID = sharedDefaults.object(forKey: WPStatsTodayWidgetUserDefaultsSiteIdKey) as? NSNumber
        siteName = sharedDefaults.string(forKey: WPStatsTodayWidgetUserDefaultsSiteNameKey) ?? ""
        siteUrl = sharedDefaults.string(forKey: WPStatsTodayWidgetUserDefaultsSiteUrlKey) ?? ""
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
        likeCount = data.likes
        commentCount = data.comments
    }

    func initRows() {
        guard let row = Bundle.main.loadNibNamed(Constants.rowNibName, owner: nil, options: nil)?.first as? TwoColumnRow else {
            return
        }

        row.configure(leftColumnName: LocalizedText.views,
                      leftColumnData: Constants.noDataLabel,
                      rightColumnName: LocalizedText.visitors,
                      rightColumnData: Constants.noDataLabel)

        rowsStackView.addArrangedSubview(row)
    }

    func configureColors() {
        view.backgroundColor = .neutral(.shade20)

        configureLabel.textColor = .text
        configureButton.backgroundColor = .neutral(.shade10)
        configureButton.setTitleColor(.text, for: .normal)

        separatorLine.backgroundColor = .neutral(.shade30)
        siteNameLabel.textColor = .textSubtle
        siteUrlLabel.textColor = .textSubtle
    }

    func updateLabels() {

        siteNameLabel.text = siteName
        siteUrlLabel.text = siteUrl

        guard let row = rowsStackView.arrangedSubviews.first as? TwoColumnRow else {
            return
        }

        row.updateData(leftColumnData: displayString(for: viewCount),
                       rightColumnData: displayString(for: visitorCount))
    }

    func displayString(for value: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: value)) ?? "0"
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

    struct LocalizedText {
        static let configure = NSLocalizedString("Display your site stats for today here. Configure in the WordPress app in your site stats.", comment: "Unconfigured stats today widget helper text")
        static let openWordPress = NSLocalizedString("Open WordPress", comment: "Today widget button to launch WP app")
        static let visitors = NSLocalizedString("Visitors", comment: "Stats Visitors Label")
        static let views = NSLocalizedString("Views", comment: "Stats Views Label")
    }

    struct Constants {
        static let noDataLabel = "-"
        static let buttonCornerRadius: CGFloat = 8.0
        static let baseUrl: String = "\(WPComScheme)://"
        static let statsUrl: String = Constants.baseUrl + "viewstats?siteId="
        static let rowNibName: String = "TwoColumnRow"
    }
}
