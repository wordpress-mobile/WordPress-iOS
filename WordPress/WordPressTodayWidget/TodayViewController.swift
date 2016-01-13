import UIKit
import NotificationCenter
import WordPressComStatsiOS

class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet var siteNameLabel: UILabel!
    @IBOutlet var visitorsCountLabel: UILabel!
    @IBOutlet var visitorsLabel: UILabel!
    @IBOutlet var viewsCountLabel: UILabel!
    @IBOutlet var viewsLabel: UILabel!
    @IBOutlet var configureMeRightConstraint: NSLayoutConstraint!
    @IBOutlet var configureMeStackView: UIStackView!
    
    var siteName: String = ""
    var visitorCount: String = ""
    var viewCount: String = ""
    var siteId: NSNumber?
    var standardLeftMargin: CGFloat = 0.0
    
    var isConfigured: Bool {
        get {
            let sharedDefaults = NSUserDefaults(suiteName: WPAppGroupName)!
            let siteId = sharedDefaults.objectForKey(WPStatsTodayWidgetUserDefaultsSiteIdKey) as! NSNumber?
            let timeZoneName = sharedDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey)
            let oauth2Token = self.getOAuth2Token()
            
            return siteId != nil && timeZoneName != nil && oauth2Token != nil

        }
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        standardLeftMargin = defaultMarginInsets.left
        configureMeRightConstraint.constant = standardLeftMargin
        return defaultMarginInsets
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let sharedDefaults = NSUserDefaults(suiteName: WPAppGroupName)!
        self.siteId = sharedDefaults.objectForKey(WPStatsTodayWidgetUserDefaultsSiteIdKey) as! NSNumber?

        siteNameLabel.text = ""
        visitorsLabel.text = NSLocalizedString("Visitors", comment: "Stats Visitors Label")
        visitorsCountLabel.text = ""
        viewsLabel.text = NSLocalizedString("Views", comment: "Stats Views Label")
        viewsCountLabel.text = ""
        
        updateUIBasedOnWidgetConfiguration()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        // Manual state restoration
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(self.siteName, forKey: WPStatsTodayWidgetUserDefaultsSiteNameKey)
        userDefaults.setObject(self.visitorCount, forKey: WPStatsTodayWidgetUserDefaultsVisitorCountKey)
        userDefaults.setObject(self.viewCount, forKey: WPStatsTodayWidgetUserDefaultsViewCountKey)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUIBasedOnWidgetConfiguration()

        // Manual state restoration
        let sharedDefaults = NSUserDefaults(suiteName: WPAppGroupName)!
        self.siteName = sharedDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsSiteNameKey) ?? ""

        let userDefaults = NSUserDefaults.standardUserDefaults()
        self.visitorCount = userDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsVisitorCountKey) ?? "0"
        self.viewCount = userDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsViewCountKey) ?? "0"
        
        self.siteNameLabel?.text = self.siteName
        self.visitorsCountLabel?.text = self.visitorCount
        self.viewsCountLabel?.text = self.viewCount
    }
    
    @IBAction func launchContainingApp() {
        self.extensionContext!.openURL(NSURL(string: "\(WPCOM_SCHEME)://viewstats?siteId=\(siteId!)")!, completionHandler: nil)
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encoutered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        let sharedDefaults = NSUserDefaults(suiteName: WPAppGroupName)!
        let siteId = sharedDefaults.objectForKey(WPStatsTodayWidgetUserDefaultsSiteIdKey) as! NSNumber?
        self.siteName = sharedDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsSiteNameKey) ?? ""
        let timeZoneName = sharedDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey)
        let oauth2Token = self.getOAuth2Token()
        
        updateUIBasedOnWidgetConfiguration()

        if siteId == nil || timeZoneName == nil || oauth2Token == nil {
            WPDDLogWrapper.logError("Missing site ID, timeZone or oauth2Token")
            
            completionHandler(NCUpdateResult.Failed)
            return
        }
        
        let timeZone = NSTimeZone(name: timeZoneName!)
        let statsService: WPStatsService = WPStatsService(siteId: siteId, siteTimeZone: timeZone, oauth2Token: oauth2Token, andCacheExpirationInterval:0)
        statsService.retrieveTodayStatsWithCompletionHandler({ (wpStatsSummary: StatsSummary!, error: NSError!) -> Void in
            WPDDLogWrapper.logInfo("Downloaded data in the Today widget")
            
            self.visitorCount = wpStatsSummary.visitors
            self.viewCount = wpStatsSummary.views
            
            self.siteNameLabel?.text = self.siteName
            self.visitorsCountLabel?.text = self.visitorCount
            self.viewsCountLabel?.text = self.viewCount
            
            completionHandler(NCUpdateResult.NewData)
            }, failureHandler: { (error) -> Void in
                WPDDLogWrapper.logError("\(error)")
                
                completionHandler(NCUpdateResult.Failed)
        })
        
    }
    
    func getOAuth2Token() -> String? {
        let oauth2Token = try? SFHFKeychainUtils.getPasswordForUsername(WPStatsTodayWidgetOAuth2TokenKeychainUsername, andServiceName: WPStatsTodayWidgetOAuth2TokenKeychainServiceName, accessGroup: WPStatsTodayWidgetOAuth2TokenKeychainAccessGroup)

        return oauth2Token as String?
    }
    
    func updateUIBasedOnWidgetConfiguration() {
        siteNameLabel.hidden = !isConfigured
        visitorsCountLabel.hidden = !isConfigured
        visitorsLabel.hidden = !isConfigured
        viewsCountLabel.hidden = !isConfigured
        viewsLabel.hidden = !isConfigured
        configureMeStackView.hidden = isConfigured
    }
}