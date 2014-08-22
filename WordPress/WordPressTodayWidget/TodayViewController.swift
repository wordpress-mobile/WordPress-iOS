import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet var siteNameLabel: UILabel?
    @IBOutlet var visitorsCountLabel: UILabel?
    @IBOutlet var viewsCountLabel: UILabel?
    @IBOutlet var topPostLabel: UILabel?
    
    var siteName: String = ""
    var visitorCount: String = ""
    var viewCount: String = ""
    var topPostTitle: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("*********** TodayViewController viewDidLoad()")
        
        // Do any additional setup after loading the view from its nib.
        
        let sharedDefaults = NSUserDefaults(suiteName: "group.org.wordpress")
        let siteId = sharedDefaults.objectForKey("WordPressTodayWidgetSiteId") as NSNumber?
        let oauth2Token = sharedDefaults.stringForKey("WordPressTodayWidgetOAuth2Token")
        
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
        userDefaults.setObject(self.topPostTitle, forKey: "TodayTopPostTitle")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let sharedDefaults = NSUserDefaults(suiteName: "group.org.wordpress")
        self.siteName = sharedDefaults.stringForKey("WordPressTodayWidgetSiteName") ?? ""

        let userDefaults = NSUserDefaults.standardUserDefaults()
        self.visitorCount = userDefaults.stringForKey("TodayVisitorCount") ?? ""
        self.viewCount = userDefaults.stringForKey("TodayViewCount") ?? ""
        self.topPostTitle = userDefaults.stringForKey("TodayTopPostTitle") ?? ""

        NSLog("*********** TodayViewController viewWillAppear: siteName:\(self.siteName), visitorCount:\(self.visitorCount)")
        
        self.siteNameLabel?.text = self.siteName
        self.visitorsCountLabel?.text = self.visitorCount
        self.viewsCountLabel?.text = self.viewCount
        self.topPostLabel?.text = self.topPostTitle
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        NSLog("*********** TodayViewController widgetPerformUpdateWithCompletionHandler()")
        // Perform any setup necessary in order to update the view.
        
        // If an error is encoutered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        let sharedDefaults = NSUserDefaults(suiteName: "group.org.wordpress")
        let siteId = sharedDefaults.objectForKey("WordPressTodayWidgetSiteId") as NSNumber?
        self.siteName = sharedDefaults.stringForKey("WordPressTodayWidgetSiteName") ?? ""
        let timeZoneName = sharedDefaults.stringForKey("WordPressTodayWidgetTimeZone")
        let oauth2Token = sharedDefaults.stringForKey("WordPressTodayWidgetOAuth2Token")
        
        if siteId == nil || timeZoneName == nil || oauth2Token == nil {
            WPDDLogWrapper.logError("Missing site ID, timeZone or oauth2Token")
            completionHandler(NCUpdateResult.Failed)
            
            let bundle = NSBundle(forClass: TodayViewController.classForCoder())
            NCWidgetController.widgetController().setHasContent(false, forWidgetWithBundleIdentifier: bundle.bundleIdentifier)
            
            return
        }
        
        let timeZone = NSTimeZone(name: timeZoneName)
        var statsService: WPStatsService = WPStatsService(siteId: siteId, siteTimeZone: timeZone, andOAuth2Token: oauth2Token)
        statsService.retrieveStatsWithCompletionHandler({ (wpStatsSummary: WPStatsSummary!, topPosts, something2, something3, something4, something5, viewsVisitors) -> Void in
            WPDDLogWrapper.logInfo("Downloaded data in the Today widget")
            
            var topPostsArray = topPosts["today"] as NSArray
            var topPost = topPostsArray[0] as WPStatsTopPost
            self.topPostTitle = topPost.title
            
            var numberFormatter = NSNumberFormatter()
            numberFormatter.locale = NSLocale.currentLocale()
            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
            numberFormatter.maximumFractionDigits = 0
            
            self.visitorCount = numberFormatter.stringFromNumber(wpStatsSummary.visitorCountToday)
            self.viewCount = numberFormatter.stringFromNumber(wpStatsSummary.viewCountToday)
            
            self.siteNameLabel?.text = self.siteName
            self.visitorsCountLabel?.text = self.visitorCount
            self.viewsCountLabel?.text = self.viewCount
            self.topPostLabel?.text = self.topPostTitle
            
            completionHandler(NCUpdateResult.NewData)
            }, failureHandler: { (error) -> Void in
                WPDDLogWrapper.logError("\(error)")
                
                completionHandler(NCUpdateResult.Failed)
        })
        
    }
    
}