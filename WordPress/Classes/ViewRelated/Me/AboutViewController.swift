import Foundation
import WordPressShared
import WordPressComAnalytics
import WordPress_AppbotX

public class AboutViewController : UITableViewController
{
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationItem()
        setupTableViewFooter()
        setupTableView()
        setupDismissButtonIfNeeded()
    }
    
    
    // MARK: - Private Helpers
    private func setupNavigationItem() {
        title = NSLocalizedString("About", comment: "About this app (information page title)")
        
        // Don't show 'About' in the next-view back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .Plain, target: nil, action: nil)
    }
    
    private func setupTableView() {
        // Load and Tint the Logo
        let color                   = WPStyleGuide.wordPressBlue()
        let tintedImage             = UIImage(named: "icon-wp")?.imageTintedWithColor(color)
        let imageView               = UIImageView(image: tintedImage)
        imageView.autoresizingMask  = [.FlexibleLeftMargin, .FlexibleRightMargin]
        imageView.contentMode       = .Top
        
        // Let's add a bottom padding!
        imageView.frame.size.height += iconBottomPadding
        
        // Finally, setup the TableView
        tableView.tableHeaderView   = imageView
        tableView.contentInset      = WPTableViewContentInsets
     
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    private func setupTableViewFooter() {
        let calendar                = NSCalendar.currentCalendar()
        let year                    = calendar.components(.Year, fromDate: NSDate()).year

        let footerView              = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Footer)
        footerView.title            = NSLocalizedString("© \(year) Automattic, Inc.", comment: "About View's Footer Text")
        footerView.titleAlignment   = .Center
        self.footerView             = footerView
    }
    
    private func setupDismissButtonIfNeeded() {
        // Don't display a dismiss button, unless this is the only view in the stack!
        if navigationController?.viewControllers.count > 1 {
            return
        }
        
        let title = NSLocalizedString("Close", comment: "Dismiss the current view")
        let style = WPStyleGuide.barButtonStyleForBordered()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: title, style: style, target: self, action: #selector(AboutViewController.dismissWasPressed(_:)))
    }

    
    
    // MARK: - Button Helpers
    @IBAction func dismissWasPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    // MARK: - UITableView Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return rows.count
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows[section].count
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier)
        if cell == nil {
            cell = WPTableViewCell(style: .Value1, reuseIdentifier: reuseIdentifier)
        }
        
        let row = rows[indexPath.section][indexPath.row]
        
        cell!.textLabel?.text       = row.title
        cell!.detailTextLabel?.text = row.details ?? String()
        if (row.handler != nil) {
            WPStyleGuide.configureTableViewActionCell(cell)
        } else {
            WPStyleGuide.configureTableViewCell(cell)
            cell?.selectionStyle = .None
        }
        
        return cell!
    }
    
    public override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let isLastSection = section == (rows.count - 1)
        if isLastSection == false || footerView == nil {
            return CGFloat.min
        }
        
        let height = WPTableViewSectionHeaderFooterView.heightForFooter(footerView!.title, width: view.frame.width)
        return height + footerBottomPadding
    }

    public override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section != (rows.count - 1) {
            return nil
        }
        
        return footerView
    }
    
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)
        
        if let handler = rows[indexPath.section][indexPath.row].handler {
            handler()
        }
    }
    
    
    
    // MARK: - Private Helpers
    private func displayWebView(url: String) {
        let webViewController = WPWebViewController(URL: NSURL(string: url)!)
        if presentingViewController != nil {
            navigationController?.pushViewController(webViewController, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: webViewController)
            presentViewController(navController, animated: true, completion: nil)
        }
    }

    private func displayRatingPrompt() {
        // Note: 
        // Let's follow the same procedure executed as in NotificationsViewController, so that if the user
        // manually decides to rate the app, we don't render the prompt!
        //
        WPAnalytics.track(.AppReviewsRatedApp)
        AppRatingUtility.ratedCurrentVersion()
        ABXAppStore.openAppStoreForApp(WPiTunesAppId)
    }
    
    private func displayTwitterAccount() {
        let twitterURL = NSURL(string: WPTwitterWordPressMobileURL)!
        UIApplication.sharedApplication().openURL(twitterURL)
    }
    
    // MARK: - Nested Row Class
    private class Row {
        let title   : String
        let details : String?
        let handler : (Void -> Void)?
        
        init(title: String, details: String?, handler: (Void -> Void)?) {
            self.title      = title
            self.details    = details
            self.handler    = handler
        }
    }

    
    
    // MARK: - Private Constants
    private let reuseIdentifier = "reuseIdentifierValue1"
    private let iconBottomPadding   = CGFloat(30)
    private let footerBottomPadding = CGFloat(12)
    
    // MARK: - Private Properties
    private var footerView : WPTableViewSectionHeaderFooterView!
    
    private var rows : [[Row]] {
        let appsBlogHostname = NSURL(string: WPAutomatticAppsBlogURL)?.host ?? String()
        
        return [
            [
                Row(title:   NSLocalizedString("Version", comment: "Displays the version of the App"),
                    details: NSBundle.mainBundle().shortVersionString(),
                    handler: nil),
                
                Row(title:   NSLocalizedString("Terms of Service", comment: "Opens the Terms of Service Web"),
                    details: nil,
                    handler: { self.displayWebView(WPAutomatticTermsOfServiceURL) }),
                
                Row(title:   NSLocalizedString("Privacy Policy", comment: "Opens the Privacy Policy Web"),
                    details: nil,
                    handler: { self.displayWebView(WPAutomatticPrivacyURL) }),
            ],
            [
                Row(title:   NSLocalizedString("Twitter", comment: "Launches the Twitter App"),
                    details: WPTwitterWordPressHandle,
                    handler: { self.displayTwitterAccount() }),
                
                Row(title:   NSLocalizedString("Blog", comment: "Opens the WordPress Mobile Blog"),
                    details: appsBlogHostname,
                    handler: { self.displayWebView(WPAutomatticAppsBlogURL) }),
                
                Row(title:   NSLocalizedString("Rate us on the App Store", comment: "Prompts the user to rate us on the store"),
                    details: nil,
                    handler: { self.displayRatingPrompt() }),
                
                Row(title:   NSLocalizedString("Source Code", comment: "Opens the Github Repository Web"),
                    details: nil,
                    handler: { self.displayWebView(WPGithubMainURL) }),
            ]
        ]
    }
}
