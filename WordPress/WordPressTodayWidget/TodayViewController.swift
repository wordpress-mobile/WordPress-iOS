import UIKit
import NotificationCenter
import WordPressComStatsiOS
import WordPressShared

class TodayViewController: UIViewController {
    @IBOutlet var siteNameLabel: UILabel!
    @IBOutlet var countContainerView: UIView!
    @IBOutlet var countContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var visitorsCountLabel: UILabel!
    @IBOutlet var visitorsLabel: UILabel!
    @IBOutlet var viewsCountLabel: UILabel!
    @IBOutlet var viewsLabel: UILabel!
    @IBOutlet var configureMeLabel: UILabel!
    @IBOutlet var configureMeLabelRightConstraint: NSLayoutConstraint!
    @IBOutlet var configureMeButtonContainerView: UIView!
    @IBOutlet var configureMeButtonContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var configureMeButtonContainerViewRightConstraint: NSLayoutConstraint!
    @IBOutlet var configureMeButton: UIButton!
    
    var siteID: NSNumber?
    var timeZone: NSTimeZone?
    var oauthToken: String?
    
    var siteNameLabelHeightConstraint: NSLayoutConstraint!
    var configureMeLabelHeightConstraint: NSLayoutConstraint!
    
    var siteName: String = ""
    var visitorCount: String = ""
    var viewCount: String = ""
    var standardLeftMargin: CGFloat = 0.0
    var standardButtonContainerViewHeight: CGFloat = 0.0
    var standardCountContainerViewHeight: CGFloat = 0.0
    
    var isConfigured = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backgroundImage = UIImage(color: WPStyleGuide.wordPressBlue()).resizableImageWithCapInsets(UIEdgeInsetsZero)
        
        configureMeLabel.text = NSLocalizedString("Display your site stats for today here. Configure in the WordPress app under your site > Stats > Today.", comment: "Unconfigured stats today widget helper text")
        configureMeButton.setTitle(NSLocalizedString("Open WordPress", comment: "Today widget button to launch WP app"), forState: .Normal)
        configureMeButton.setBackgroundImage(backgroundImage, forState: .Normal)
        configureMeButton.clipsToBounds = true
        configureMeButton.layer.cornerRadius = 5.0
        
        siteNameLabel.text = "-"
        visitorsLabel.text = NSLocalizedString("Visitors", comment: "Stats Visitors Label")
        visitorsCountLabel.text = "-"
        viewsLabel.text = NSLocalizedString("Views", comment: "Stats Views Label")
        viewsCountLabel.text = "-"
        
        siteNameLabelHeightConstraint = NSLayoutConstraint(item: siteNameLabel, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0.0, constant: 0.0)
        siteNameLabel.addConstraint(siteNameLabelHeightConstraint)
        configureMeLabelHeightConstraint = NSLayoutConstraint(item: configureMeLabel, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0.0, constant: 0.0)
        configureMeLabel.addConstraint(configureMeLabelHeightConstraint)
        
        standardButtonContainerViewHeight = configureMeButtonContainerViewHeightConstraint.constant
        standardCountContainerViewHeight = countContainerViewHeightConstraint.constant

        retrieveSiteConfiguration()
        updateUIBasedOnWidgetConfiguration()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Manual state restoration
        let sharedDefaults = NSUserDefaults(suiteName: WPAppGroupName)!
        siteName = sharedDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsSiteNameKey) ?? ""

        let userDefaults = NSUserDefaults.standardUserDefaults()
        visitorCount = userDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsVisitorCountKey) ?? "0"
        viewCount = userDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsViewCountKey) ?? "0"
        
        siteNameLabel.text = siteName
        visitorsCountLabel.text = visitorCount
        viewsCountLabel.text = viewCount
        
        retrieveSiteConfiguration()
        updateUIBasedOnWidgetConfiguration()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Manual state restoration
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(visitorCount, forKey: WPStatsTodayWidgetUserDefaultsVisitorCountKey)
        userDefaults.setObject(viewCount, forKey: WPStatsTodayWidgetUserDefaultsViewCountKey)
    }
    
    @IBAction func launchContainingApp() {
        if let unwrappedSiteID = siteID {
            extensionContext!.openURL(NSURL(string: "\(WPComScheme)://viewstats?siteId=\(unwrappedSiteID)")!, completionHandler: nil)
        } else {
            extensionContext!.openURL(NSURL(string: "\(WPComScheme)://")!, completionHandler: nil)
        }
    }
    
    func updateUIBasedOnWidgetConfiguration() {
        siteNameLabel.hidden = !isConfigured
        siteNameLabelHeightConstraint.active = !isConfigured
        countContainerView.hidden = !isConfigured
        countContainerViewHeightConstraint.constant = isConfigured ? standardCountContainerViewHeight : 8
        configureMeButtonContainerView.hidden = isConfigured
        configureMeButtonContainerViewHeightConstraint.constant = isConfigured ? 0 : standardButtonContainerViewHeight
        configureMeLabel.hidden = isConfigured
        configureMeLabelHeightConstraint.active = isConfigured
        
        view.setNeedsUpdateConstraints()
    }
    
    func retrieveSiteConfiguration() {
        let sharedDefaults = NSUserDefaults(suiteName: WPAppGroupName)!
        siteID = sharedDefaults.objectForKey(WPStatsTodayWidgetUserDefaultsSiteIdKey) as? NSNumber
        siteName = sharedDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsSiteNameKey) ?? ""
        oauthToken = fetchOAuthBearerToken()
        
        if let timeZoneName = sharedDefaults.stringForKey(WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey) {
            timeZone = NSTimeZone(name: timeZoneName)
        }
        
        isConfigured = siteID != nil && timeZone != nil && oauthToken != nil
    }

    func fetchOAuthBearerToken() -> String? {
        let oauth2Token = try? SFHFKeychainUtils.getPasswordForUsername(WPStatsTodayWidgetOAuth2TokenKeychainUsername, andServiceName: WPStatsTodayWidgetOAuth2TokenKeychainServiceName, accessGroup: WPStatsTodayWidgetOAuth2TokenKeychainAccessGroup)
        
        return oauth2Token as String?
    }
}

extension TodayViewController: NCWidgetProviding {
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        standardLeftMargin = defaultMarginInsets.left
        configureMeLabelRightConstraint.constant = standardLeftMargin
        configureMeButtonContainerViewRightConstraint.constant = standardLeftMargin
        
        return defaultMarginInsets
    }
    
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        retrieveSiteConfiguration()
        dispatch_async(dispatch_get_main_queue()) {
            self.updateUIBasedOnWidgetConfiguration()
        }
        
        if isConfigured == false {
            WPDDLogWrapper.logError("Missing site ID, timeZone or oauth2Token")
            
            completionHandler(NCUpdateResult.Failed)
            return
        }
        
        let statsService: WPStatsService = WPStatsService(siteId: siteID, siteTimeZone: timeZone, oauth2Token: oauthToken, andCacheExpirationInterval:0)
        statsService.retrieveTodayStatsWithCompletionHandler({ wpStatsSummary, error in
            WPDDLogWrapper.logInfo("Downloaded data in the Today widget")
            
            dispatch_async(dispatch_get_main_queue()) {
                self.visitorCount = wpStatsSummary.visitors
                self.viewCount = wpStatsSummary.views
                
                self.siteNameLabel?.text = self.siteName
                self.visitorsCountLabel?.text = self.visitorCount
                self.viewsCountLabel?.text = self.viewCount
            }
            completionHandler(NCUpdateResult.NewData)
            }, failureHandler: { error in
                WPDDLogWrapper.logError("\(error)")
                
                completionHandler(NCUpdateResult.Failed)
        })
        
    }
}
