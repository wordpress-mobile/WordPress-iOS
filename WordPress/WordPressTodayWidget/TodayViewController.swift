import UIKit
import NotificationCenter
import WordPressComStatsiOS

class TodayViewController: UIViewController {
    @IBOutlet var siteNameLabel: UILabel!
    @IBOutlet var countContainerView: UIView!
    @IBOutlet var visitorsCountLabel: UILabel!
    @IBOutlet var visitorsLabel: UILabel!
    @IBOutlet var viewsCountLabel: UILabel!
    @IBOutlet var viewsLabel: UILabel!
    @IBOutlet var configureMeRightConstraint: NSLayoutConstraint!
    @IBOutlet var configureMeLabel: UILabel!
    @IBOutlet var configureMeButton: UIButton!
    
    var siteID: NSNumber?
    var timeZone: NSTimeZone?
    var oauthToken: String?
    
    var siteName: String = ""
    var visitorCount: String = ""
    var viewCount: String = ""
    var standardLeftMargin: CGFloat = 0.0
    
    var isConfigured = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureMeLabel.text = NSLocalizedString("Display your site stats for today here. Configure in the WordPress app under your Site, Stats, Today.", comment: "Unconfigured stats today widget helper text")
        configureMeButton.setTitle(NSLocalizedString("Launch WordPress", comment: "Today widget button to launch WP app"), forState: .Normal)
        siteNameLabel.text = "-"
        visitorsLabel.text = NSLocalizedString("Visitors", comment: "Stats Visitors Label")
        visitorsCountLabel.text = "-"
        viewsLabel.text = NSLocalizedString("Views", comment: "Stats Views Label")
        viewsCountLabel.text = "-"
        
        retrieveSiteConfiguration()
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
        
        // Manual state restoration
        let sharedDefaults = NSUserDefaults(suiteName: WPAppGroupName)!
        self.siteName = sharedDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsSiteNameKey) ?? ""

        let userDefaults = NSUserDefaults.standardUserDefaults()
        self.visitorCount = userDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsVisitorCountKey) ?? "0"
        self.viewCount = userDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsViewCountKey) ?? "0"
        
        self.siteNameLabel.text = self.siteName
        self.visitorsCountLabel.text = self.visitorCount
        self.viewsCountLabel.text = self.viewCount
    }
    
    @IBAction func launchContainingApp() {
        if let unwrappedSiteID = siteID {
            self.extensionContext!.openURL(NSURL(string: "\(WPCOM_SCHEME)://viewstats?siteId=\(unwrappedSiteID)")!, completionHandler: nil)
        } else {
            self.extensionContext!.openURL(NSURL(string: "\(WPCOM_SCHEME)://")!, completionHandler: nil)
        }
    }
    
    func getOAuth2Token() -> String? {
        let oauth2Token = try? SFHFKeychainUtils.getPasswordForUsername(WPStatsTodayWidgetOAuth2TokenKeychainUsername, andServiceName: WPStatsTodayWidgetOAuth2TokenKeychainServiceName, accessGroup: WPStatsTodayWidgetOAuth2TokenKeychainAccessGroup)
        
        return oauth2Token as String?
    }
    
    func updateUIBasedOnWidgetConfiguration() {
        siteNameLabel.hidden = !isConfigured
        countContainerView.hidden = !isConfigured
        configureMeLabel.hidden = isConfigured
        configureMeButton.hidden = isConfigured
        configureMeRightConstraint.constant = isConfigured ? 0.0 : standardLeftMargin
    }
    
    func retrieveSiteConfiguration() {
        let sharedDefaults = NSUserDefaults(suiteName: WPAppGroupName)!
        siteID = sharedDefaults.objectForKey(WPStatsTodayWidgetUserDefaultsSiteIdKey) as! NSNumber?
        siteName = sharedDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsSiteNameKey) ?? ""
        oauthToken = self.getOAuth2Token()
        
        if let timeZoneName = sharedDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey) {
            timeZone = NSTimeZone(name: timeZoneName)
        }
        
        isConfigured = siteID != nil && timeZone != nil && oauthToken != nil
    }
}

extension TodayViewController: NCWidgetProviding {
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        standardLeftMargin = defaultMarginInsets.left
        configureMeRightConstraint.constant = standardLeftMargin
        return defaultMarginInsets
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        retrieveSiteConfiguration()
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.updateUIBasedOnWidgetConfiguration()
        }
        
        if isConfigured == false {
            WPDDLogWrapper.logError("Missing site ID, timeZone or oauth2Token")
            
            completionHandler(NCUpdateResult.Failed)
            return
        }
        
        let statsService: WPStatsService = WPStatsService(siteId: siteID, siteTimeZone: timeZone, oauth2Token: oauthToken, andCacheExpirationInterval:0)
        statsService.retrieveTodayStatsWithCompletionHandler({ (wpStatsSummary: StatsSummary!, error: NSError!) -> Void in
            WPDDLogWrapper.logInfo("Downloaded data in the Today widget")
            
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.visitorCount = wpStatsSummary.visitors
                self.viewCount = wpStatsSummary.views
                
                self.siteNameLabel?.text = self.siteName
                self.visitorsCountLabel?.text = self.visitorCount
                self.viewsCountLabel?.text = self.viewCount
            }
            completionHandler(NCUpdateResult.NewData)
            }, failureHandler: { (error) -> Void in
                WPDDLogWrapper.logError("\(error)")
                
                completionHandler(NCUpdateResult.Failed)
        })
        
    }
}
