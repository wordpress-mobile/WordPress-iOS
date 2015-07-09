import Foundation


public class AboutViewController : UITableViewController
{
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("About", comment: "About this app (information page title)")
        
        // Setup Interface
        setupTableView()
        setupDismissButtonIfNeeded()
    }
    
    
    // MARK: - Private Helpers
    private func setupTableView() {
        // Load and Tint the Logo
        let color                   = WPStyleGuide.wordPressBlue()
        let tintedImage             = UIImage(named: "icon-wp")?.imageTintedWithColor(color)
        let imageView               = UIImageView(image: tintedImage)
        imageView.autoresizingMask  = .FlexibleLeftMargin | .FlexibleRightMargin
        imageView.contentMode       = .Top
        
        // Let's add a bottom padding!
        imageView.frame.size.height += iconBottomPadding
        
        // Finally, setup the TableView
        tableView.tableHeaderView   = imageView
        tableView.contentInset      = WPTableViewContentInsets
        
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    private func setupDismissButtonIfNeeded() {
        if navigationController?.viewControllers.count > 1 {
            return
        }
        
        let title = NSLocalizedString("Close", comment: "Dismiss the current view")
        let style = WPStyleGuide.barButtonStyleForBordered()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: title, style: style, target: self, action: "dismissWasPressed:")
    }

    
    
    // MARK: - Button Helpers
    @IBAction private func dismissWasPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    // MARK: - UITableView Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return rowTitles.count
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowTitles[section].count
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as? UITableViewCell
        if cell == nil {
            cell = UITableViewCell(style: .Value1, reuseIdentifier: reuseIdentifier)
            WPStyleGuide.configureTableViewCell(cell)
        }
        
        let hasRowHandler           = rowHandlers[indexPath.section][indexPath.row] != nil
        
        cell!.textLabel?.text       = rowTitles[indexPath.section][indexPath.row]
        cell!.detailTextLabel?.text = rowDetails[indexPath.section][indexPath.row]
        cell!.accessoryType         = hasRowHandler ? .DisclosureIndicator : .None
        
        return cell!
    }
    
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)
        
        if let handler = rowHandlers[indexPath.section][indexPath.row] {
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
        WPAnalytics.track(WPAnalyticsStat.AppReviewsRatedApp)
        AppRatingUtility.ratedCurrentVersion()
        ABXAppStore.openAppStoreForApp(WPiTunesAppId)
    }
    
    private func displayTwitterComposer() {
        if isTwitterUnavailable() {
            return
        }

        let twitterURL = NSURL(string: WPTwitterWordPressMobileURL)!
        UIApplication.sharedApplication().openURL(twitterURL)

    }
    
    
    // MARK: - Twitter Helpers
    private func isTwitterUnavailable() -> Bool {
        let emptyTwitterURL = NSURL(string: WPTwitterWordPressMobileURL)!
        return UIApplication.sharedApplication().canOpenURL(emptyTwitterURL) == false
    }
    
    private func filterDisabledRows<T>(array: [[T]]) -> [[T]] {
        var filtered = array
        
        if isTwitterUnavailable() {
            var section = array[twitterIndexPath.section] as [T]
            section.removeAtIndex(twitterIndexPath.row)
            filtered[twitterIndexPath.section] = section
        }
        
        return filtered
    }
    
    

    // MARK: - Private Constants
    private let reuseIdentifier         = "reuseIdentifierValue1"
    private let twitterIndexPath        = NSIndexPath(forRow: 0, inSection: 1)
    private let iconBottomPadding       = CGFloat(30)
    
    // MARK: - Private Aliases
    typealias RowHandler = (Void -> Void)
    
    // MARK: - Private Properties
    private var rowTitles : [[String]] {
        return filterDisabledRows([
            [
                NSLocalizedString("Version",                    comment: "Displays the version of the App"),
                NSLocalizedString("Terms of Service",           comment: "Opens the Terms of Service Web"),
                NSLocalizedString("Privacy Policy",             comment: "Opens the Privacy Policy Web")
            ],
            [
                NSLocalizedString("Twitter",                    comment: "Launches the Twitter App"),
                NSLocalizedString("Blog",                       comment: "Opens the WordPress Mobile Blog"),
                NSLocalizedString("Rate Us on the App Store",   comment: "Prompts the user to rate us on the store"),
                NSLocalizedString("Source Code",                comment: "Opens the Github Repository Web")
            ]
        ])
    }
    
    private var rowDetails : [[String]] {
        let appsBlogHostname = NSURL(string: WPAutomatticAppsBlogURL)?.host ?? String()

        return filterDisabledRows([
            [
                NSBundle.mainBundle().detailedVersionNumber(),
                String(),
                String()
            ],
            [
                WPTwitterWordPressHandle,
                appsBlogHostname,
                String(),
                String()
            ]
        ])
    }
    
    private var rowHandlers : [[ RowHandler? ]] {
        return filterDisabledRows([
            [
                nil,
                { self.displayWebView(WPAutomatticTermsOfServiceURL) },
                { self.displayWebView(WPAutomatticPrivacyURL) }
            ],
            [
                { self.displayTwitterComposer() },
                { self.displayWebView(WPAutomatticAppsBlogURL) },
                { self.displayRatingPrompt() },
                { self.displayWebView(WPGithubMainURL) }
            ]
        ])
    }
}
