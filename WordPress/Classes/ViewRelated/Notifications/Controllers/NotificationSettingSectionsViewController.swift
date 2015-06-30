import Foundation


public class NotificationSettingSectionsViewController : UITableViewController
{
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Interface
        setupNavigationItem()
        setupTableView()
        
        // Load Blogs + Settings
        loadBlogList()
        loadNotificationSettings()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Manually deselect the selected row. This is required due to a bug in iOS7 / iOS8
        tableView.deselectSelectedRowWithAnimation(true)
    }

    

    // MARK: - Setup Helpers
    private func setupNavigationItem() {
        let closeTitle  = NSLocalizedString("Close", comment: "Close the currrent screen. Action")
        let closeAction = Selector("dismissWasPressed:")
        
        title = NSLocalizedString("Settings", comment: "Title displayed in the Notification settings")
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: closeTitle, style: .Plain, target: self, action: closeAction)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .Plain, target: nil, action: nil)
    }
    
    private func setupTableView() {
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    
    
    // MARK: - Service Helpers
    private func loadBlogList() {
// TODO: Filter
        let service = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        if let allBlogs = service.blogsForAllAccounts() as? [Blog] {
            blogs = allBlogs
        }
    }
    
    private func loadNotificationSettings() {
// TODO: Spinner
        let service = NotificationsService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.getAllSettings({
                (settings: NotificationSettings) in
                self.settings = settings
            },
            failure: {
                (error: NSError!) in
                
            })
    }



    // MARK: - UITableView Delegate Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Section.Count
    }

    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (section == Section.Blog.rawValue) ? (blogs?.count ?? emptyRowCount) : (defaultRowCount)
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! UITableViewCell
        
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }



    // MARK: - UITableView Delegate Methods
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let settings: AnyObject = settingsAtIndexPath(indexPath) {
            let identifier = NotificationSettingDetailsViewController.classNameWithoutNamespaces()
            performSegueWithIdentifier(identifier, sender: settings)
        } else {
            tableView.deselectSelectedRowWithAnimation(true)
        }
    }


    
    // MARK: - UITableView Helpers
    private func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        let description : String
        
        switch Section(rawValue: indexPath.section)! {
        case .Blog:
            description = blogs?[indexPath.row].blogName ?? String()
        case .Other:
            description = NSLocalizedString("Comments on Other Sites", comment: "Displayed in the Notification Settings")
        case .WordPress:
            description = NSLocalizedString("Updates from WordPress.com", comment: "Displayed in the Notification Settings")
        }

        cell.textLabel?.text = description
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    private func blogIdAtRow(row: Int) -> Int? {
        return blogs?[row].blogID?.integerValue
    }
    
    private func settingsAtIndexPath(indexPath: NSIndexPath) -> AnyObject? {
        switch indexPath.section {
        case Section.Blog.rawValue:
            return settings?.settingsForSiteWithId(blogIdAtRow(indexPath.row))
            
        case Section.Other.rawValue:
            return settings?.other
            
        case Section.WordPress.rawValue:
            return settings?.wpcom
            
        default:
            return nil
        }
    }
    
    
    
    // MARK: - Segue Helpers
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let detailsViewController = segue.destinationViewController as? NotificationSettingDetailsViewController {
            
            if let siteSettings = sender as? [NotificationSettings.Site] {
                detailsViewController.setupWithSiteSettings(siteSettings)
                
            } else if let otherSettings = sender as? [NotificationSettings.Other] {
                detailsViewController.setupWithOtherSettings(otherSettings)
                
            } else if let wpcom = sender as? NotificationSettings.WordPressCom {
                detailsViewController.setupWithWordPressSettings(wpcom)
            }
        }
    }

    
    
    // MARK: - Button Handlers
    public func dismissWasPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }



    // MARK: - Table Sections
    private enum Section : Int {
        case Blog        = 0
        case Other
        case WordPress
        static let Count = 3
    }

    // MARK: - Private Constants
    private let emptyRowCount           = 0
    private let defaultRowCount         = 1
    private let reuseIdentifier         = "NotificationSettingsTableViewCell"
    
    // MARK: - Private Properties
    private var blogs                   : [Blog]?
    private var settings                : NotificationSettings?
}
