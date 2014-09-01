import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet var siteNameLabel: UILabel?
    @IBOutlet var visitorsCountLabel: UILabel?
    @IBOutlet var visitorsLabel: UILabel?
    @IBOutlet var viewsCountLabel: UILabel?
    @IBOutlet var viewsLabel: UILabel?
    
    var siteName: String = ""
    var visitorCount: String = ""
    var viewCount: String = ""
    var siteId: NSNumber?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        let sharedDefaults = NSUserDefaults(suiteName: "group.org.wordpress")
        siteId = sharedDefaults.objectForKey("WordPressTodayWidgetSiteId") as NSNumber?
        let oauth2Token = self.getOAuth2Token()
        visitorsLabel?.text = NSLocalizedString("Visitors", comment: "Stats Visitors Label")
        viewsLabel?.text = NSLocalizedString("Views", comment: "Stats Views Label")
        
        if siteId == nil || oauth2Token == nil {
            // Dynamically determine bundle ID so it doesn't have to be hardcoded
            let bundle = NSBundle(forClass: TodayViewController.classForCoder())
            NCWidgetController.widgetController().setHasContent(false, forWidgetWithBundleIdentifier: bundle.bundleIdentifier)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        var userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(self.siteName, forKey: "TodaySiteName")
        userDefaults.setObject(self.visitorCount, forKey: "TodayVisitorCount")
        userDefaults.setObject(self.viewCount, forKey: "TodayViewCount")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let sharedDefaults = NSUserDefaults(suiteName: "group.org.wordpress")
        self.siteName = sharedDefaults.stringForKey("WordPressTodayWidgetSiteName") ?? ""

        let userDefaults = NSUserDefaults.standardUserDefaults()
        self.visitorCount = userDefaults.stringForKey("TodayVisitorCount") ?? ""
        self.viewCount = userDefaults.stringForKey("TodayViewCount") ?? ""
        
        self.siteNameLabel?.text = self.siteName
        self.visitorsCountLabel?.text = self.visitorCount
        self.viewsCountLabel?.text = self.viewCount
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func launchContainingApp() {
        self.extensionContext.openURL(NSURL(string: "wordpress://viewstats?siteId=\(siteId!)"), completionHandler: nil)
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encoutered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        let sharedDefaults = NSUserDefaults(suiteName: "group.org.wordpress")
        let siteId = sharedDefaults.objectForKey("WordPressTodayWidgetSiteId") as NSNumber?
        self.siteName = sharedDefaults.stringForKey("WordPressTodayWidgetSiteName") ?? ""
        let timeZoneName = sharedDefaults.stringForKey("WordPressTodayWidgetTimeZone")
        let oauth2Token = self.getOAuth2Token()
        
        if siteId == nil || timeZoneName == nil || oauth2Token == nil {
            WPDDLogWrapper.logError("Missing site ID, timeZone or oauth2Token")
            completionHandler(NCUpdateResult.Failed)
            
            let bundle = NSBundle(forClass: TodayViewController.classForCoder())
            NCWidgetController.widgetController().setHasContent(false, forWidgetWithBundleIdentifier: bundle.bundleIdentifier)
            
            return
        }
        
        let timeZone = NSTimeZone(name: timeZoneName)
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
        if UIDevice.currentDevice().model == "iPhone Simulator" {
            let sharedDefaults = NSUserDefaults(suiteName: "group.org.wordpress")
            let oauth2Token = sharedDefaults.stringForKey("WordPressTodayWidgetOAuth2Token")
            return oauth2Token
        }
        
        var error:NSError?
        
        let oauth2Token = SFHFKeychainUtils.getPasswordForUsername("OAuth2Token", andServiceName: "TodayWidget", accessGroup: "3TMU3BH3NK.org.wordpress", error: &error)
        
        NSLog("Token: \(oauth2Token)")
        
        return oauth2Token
    }
    
}