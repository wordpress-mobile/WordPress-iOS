import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet var siteNameLabel: UILabel!
    @IBOutlet var visitorsCountLabel: UILabel!
    @IBOutlet var visitorsLabel: UILabel!
    @IBOutlet var viewsCountLabel: UILabel!
    @IBOutlet var viewsLabel: UILabel!
    
    var siteName: String = ""
    var visitorCount: String = ""
    var viewCount: String = ""
    var siteId: NSNumber?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let sharedDefaults = NSUserDefaults(suiteName: WPAppGroupName)
        self.siteId = sharedDefaults.objectForKey(WPStatsTodayWidgetUserDefaultsSiteIdKey) as NSNumber?

        visitorsLabel?.text = NSLocalizedString("Visitors", comment: "Stats Visitors Label")
        viewsLabel?.text = NSLocalizedString("Views", comment: "Stats Views Label")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        // Manual state restoration
        var userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(self.siteName, forKey: WPStatsTodayWidgetUserDefaultsSiteNameKey)
        userDefaults.setObject(self.visitorCount, forKey: WPStatsTodayWidgetUserDefaultsVisitorCountKey)
        userDefaults.setObject(self.viewCount, forKey: WPStatsTodayWidgetUserDefaultsViewCountKey)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Manual state restoration
        let sharedDefaults = NSUserDefaults(suiteName: WPAppGroupName)
        self.siteName = sharedDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsSiteNameKey) ?? ""

        let userDefaults = NSUserDefaults.standardUserDefaults()
        self.visitorCount = userDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsVisitorCountKey) ?? "0"
        self.viewCount = userDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsViewCountKey) ?? "0"
        
        self.siteNameLabel?.text = self.siteName
        self.visitorsCountLabel?.text = self.visitorCount
        self.viewsCountLabel?.text = self.viewCount
    }
    
    @IBAction func launchContainingApp() {
        self.extensionContext!.openURL(NSURL(string: "wordpress://viewstats?siteId=\(siteId!)"), completionHandler: nil)
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encoutered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        let sharedDefaults = NSUserDefaults(suiteName: WPAppGroupName)
        let siteId = sharedDefaults.objectForKey(WPStatsTodayWidgetUserDefaultsSiteIdKey) as NSNumber?
        self.siteName = sharedDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsSiteNameKey) ?? ""
        let timeZoneName = sharedDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey)
        let oauth2Token = self.getOAuth2Token()
        
        if siteId == nil || timeZoneName == nil || oauth2Token == nil {
            WPDDLogWrapper.logError("Missing site ID, timeZone or oauth2Token")
            completionHandler(NCUpdateResult.Failed)
            
            let bundle = NSBundle(forClass: TodayViewController.classForCoder())
            NCWidgetController.widgetController().setHasContent(false, forWidgetWithBundleIdentifier: bundle.bundleIdentifier)
            
            return
        }
        
        let timeZone = NSTimeZone(name: timeZoneName!)
        var statsService: WPStatsService = WPStatsService(siteId: siteId, siteTimeZone: timeZone, andOAuth2Token: oauth2Token)
        statsService.retrieveTodayStatsWithCompletionHandler({ (wpStatsSummary: WPStatsSummary!) -> Void in
            WPDDLogWrapper.logInfo("Downloaded data in the Today widget")
            
            var numberFormatter = NSNumberFormatter()
            numberFormatter.locale = NSLocale.currentLocale()
            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
            numberFormatter.maximumFractionDigits = 0
            
            self.visitorCount = numberFormatter.stringFromNumber(wpStatsSummary.visitorCountToday)
            self.viewCount = numberFormatter.stringFromNumber(wpStatsSummary.viewCountToday)
            
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
        var error:NSError?
        
        var oauth2Token:NSString? = SFHFKeychainUtils.getPasswordForUsername(WPStatsTodayWidgetOAuth2TokenKeychainUsername, andServiceName: WPStatsTodayWidgetOAuth2TokenKeychainServiceName, accessGroup: WPStatsTodayWidgetOAuth2TokenKeychainAccessGroup, error: &error)
        
        return oauth2Token
    }
    
}