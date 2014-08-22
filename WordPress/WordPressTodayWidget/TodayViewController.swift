import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet var siteNameLabel: UILabel?
    @IBOutlet var visitorsCountLabel: UILabel?
    @IBOutlet var viewsCountLabel: UILabel?
    @IBOutlet var topPostLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encoutered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        let sharedDefaults = NSUserDefaults(suiteName: "group.org.wordpress")
        let siteId = sharedDefaults.objectForKey("WordPressTodayWidgetSiteId") as NSNumber?
        let siteName = sharedDefaults.stringForKey("WordPressTodayWidgetSiteName")
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
            
            var numberFormatter = NSNumberFormatter()
            numberFormatter.locale = NSLocale.currentLocale()
            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
            numberFormatter.maximumFractionDigits = 0
            
            let visitorCountString = numberFormatter.stringFromNumber(wpStatsSummary.visitorCountToday)
            let viewCountString = numberFormatter.stringFromNumber(wpStatsSummary.viewCountToday)
            
            self.siteNameLabel?.text = siteName
            self.visitorsCountLabel?.text = visitorCountString
            self.viewsCountLabel?.text = viewCountString
            self.topPostLabel?.text = topPost.title
            
            completionHandler(NCUpdateResult.NewData)
            }, failureHandler: { (error) -> Void in
                WPDDLogWrapper.logError("\(error)")
                
                completionHandler(NCUpdateResult.Failed)
        })
        
    }
    
}