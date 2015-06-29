import Foundation


public class NotificationSettingSectionsViewController : UITableViewController
{
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationItem()
        setupTableView()
        setupBlogsList()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Manually deselect the selected row. This is required due to a bug in iOS7 / iOS8
        tableView.deselectSelectedRowWithAnimation(true)
    }



    // MARK: - UITableView Delegate Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Section.Count
    }

    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (section == Section.Blog.rawValue) ? (blogs?.count ?? emptyRowCount) : (defaultRowCount)
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell                = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! UITableViewCell
        cell.textLabel?.text    = descriptionForRow(indexPath)
        
        WPStyleGuide.configureTableViewCell(cell)
        
        return cell
    }



    // MARK: - UITableView Delegate Methods
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let identifier = NotificationSettingDetailsViewController.classNameWithoutNamespaces()
        performSegueWithIdentifier(identifier, sender: indexPath)
    }



    // MARK: - Segue Helpers
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let selectedIndexPath       = sender as? NSIndexPath
        let detailsViewController   = segue.destinationViewController as? NotificationSettingDetailsViewController
        if selectedIndexPath == nil || detailsViewController == nil {
            return
        }
        
        switch Section(rawValue: selectedIndexPath!.section)! {
        case .Blog:
            let blogId = blogs?[selectedIndexPath!.row].blogID?.integerValue
            detailsViewController?.loadBlogSettings(blogId)
        case .Other:
            detailsViewController?.loadOtherSettings()
        case .WordPress:
            detailsViewController?.loadWordPressSettings()
        }
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
    
    private func setupBlogsList() {
// TODO: Filter only dotcom and jetpack maybe?
        let service = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        if let unwrappedBlogs = service.blogsForAllAccounts() as? [Blog] {
            blogs = unwrappedBlogs
        }
    }
    
    

    // MARK: - Private Helpers
    private func descriptionForRow(indexPath: NSIndexPath) -> String {
        switch Section(rawValue: indexPath.section)! {
        case .Blog:
            return blogs?[indexPath.row].blogName ?? String()
        case .Other:
            return NSLocalizedString("Comments on Other Sites", comment: "Displayed in the Notification Settings")
        case .WordPress:
            return NSLocalizedString("Updates from WordPress.com", comment: "Displayed in the Notification Settings")
        }
    }

    
    
    // MARK: - Button Handlers
    public func dismissWasPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }



    // MARK: - Table Sections
    private enum Section : Int {
        case Blog                       = 0
        case Other                      = 1
        case WordPress                  = 2
        static let Count                = 3
    }

    // MARK: - Private Constants
    private let emptyRowCount           = 0
    private let defaultRowCount         = 1
    private let reuseIdentifier         = "NotificationSettingsTableViewCell"
    
    // MARK: - Private Properties
    private var blogs                   : [Blog]?
}
