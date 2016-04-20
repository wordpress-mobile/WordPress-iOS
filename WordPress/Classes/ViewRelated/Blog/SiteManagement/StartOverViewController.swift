import UIKit
import WordPressShared

 /// StartOverViewController allows user to trigger help session to remove site content.
 ///
public class StartOverViewController: UITableViewController
{
    // MARK: - Properties: must be set by creator
    
    /// The blog whose content we want to remove
    ///
    var blog : Blog!
    
    // MARK: - Properties: table content
    
    let headerView: TableViewHeaderDetailView = {
        let header = NSLocalizedString("Let Us Help", comment: "Heading for instructions on Start Over settings page")
        let detail = NSLocalizedString("If you want a site but don't want any of the posts and pages you have now, our support team can delete your posts, pages, media, and comments for you.\n\nThis will keep your site and URL active, but give you a fresh start on your content creation. Just contact us to have your current content cleared out.", comment: "Detail for instructions on Start Over settings page")
        
       return TableViewHeaderDetailView(title: header, detail: detail)
    }()

    let contactCell: UITableViewCell = {
        let contactTitle = NSLocalizedString("Contact Support", comment: "Button to contact support on Start Over settings page")

        let actionCell = WPTableViewCellDefault(style: .Value1, reuseIdentifier: nil)
        actionCell.textLabel?.text = contactTitle
        WPStyleGuide.configureTableViewActionCell(actionCell)
        actionCell.textLabel?.textAlignment = .Center
        
        return actionCell
    }()

    // MARK: - Initializer
    
    /// Preferred initializer for DeleteSiteViewController
    ///
    /// - Parameters:
    ///     - blog: The Blog currently at the site
    ///
    convenience init(blog: Blog) {
        self.init(style: .Grouped)
        self.blog = blog
    }
    
    // MARK: - View Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Start Over", comment: "Title of Start Over settings page")
        
        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    // MARK: Table View Data Source
    
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return contactCell
    }

    // MARK: - Table View Delegate
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        contactSupport()
    }

    override public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
    }

    override public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        headerView.layoutWidth = tableView.frame.width
        let height = headerView.intrinsicContentSize().height
        
        return height
    }

    // MARK: - Actions

    private func contactSupport() {
        tableView.deselectSelectedRowWithAnimation(true)

        if HelpshiftUtils.isHelpshiftEnabled() {
            setupHelpshift(blog.account)
            
            let metadata = helpshiftMetadata(blog)
            HelpshiftSupport.showConversation(self, withOptions: metadata)
        } else {
            if let contact = NSURL(string: "https://support.wordpress.com/contact/") {
                UIApplication.sharedApplication().openURL(contact)
            }
        }
    }

    private func setupHelpshift(account: WPAccount) {
        let user = account.userID.stringValue
        HelpshiftSupport.setUserIdentifier(user)
        
        let name = account.username
        let email = account.email
        HelpshiftCore.setName(name, andEmail: email)
    }
    
    private func helpshiftMetadata(blog: Blog) -> [NSObject: AnyObject] {
        let options: [String: String] = [
            "Source": "Start Over",
            "Blog": blog.logDescription(),
            ]

        return [HelpshiftSupportCustomMetadataKey: options]
    }
}
