import Foundation


public class NotificationSettingsViewController : UITableViewController
{
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Settings", comment: "Title displayed in the Notification settings")
        
        setupDismissButton()
        setupBlogsCollection()
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
        switch Section(rawValue: section)! {
        case .Blog:
            return blogs?.count ?? emptyRowCount
        default:
            return defaultRowCount
        }
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! UITableViewCell
        
        switch Section(rawValue: indexPath.section)! {
        case .Blog:
            cell.textLabel?.text = blogs?[indexPath.row].blogName ?? String()
        case .Other:
            cell.textLabel?.text = NSLocalizedString("Comments on Other Sites", comment: "Displayed in the Notification Settings Interface")
        case .WordPress:
            cell.textLabel?.text = NSLocalizedString("Updates from WordPress.com", comment: "Displayed in the Notification Settings Interface")
        }
        
        return cell
    }
    
    // MARK: - UITableView Delegate Methods
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .Blog:
            blogWasPressed(blogs?[indexPath.row])
        case .Other:
            otherWasPressed()
        case .WordPress:
            wordPressWasPressed()
        }
    }
    
    
    // MARK: - Private Helpers
    private func setupBlogsCollection() {
// TODO: Filter only dotcom and jetpack maybe?
        let service = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        if let unwrappedBlogs = service.blogsForAllAccounts() as? [Blog] {
            blogs = unwrappedBlogs
        }
    }
    
    private func setupDismissButton() {
        let title  = NSLocalizedString("Close", comment: "Close the currrent screen. Action")
        let action = Selector("dismissWasPressed:")

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: title, style: .Plain, target: self, action: action)
    }

    
    // MARK: - Button Handlers
    private func blogWasPressed(blog: Blog?) {
        let blogId = blog!.blogID as? Int
        if blogId == nil {
            return
        }
        
        let service = NotificationsService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.getSiteSettings(blogId!,
            success: {
                (settings: [NotificationSettings.Site]) in
            },
            failure: {
                (error: NSError!) in
            })
    }
    
    private func otherWasPressed() {
        
    }
    
    private func wordPressWasPressed() {
        
    }

    public func dismissWasPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }


    
    // MARK: - Table Sections
    private enum Section : Int {
        case Blog               = 0
        case Other              = 1
        case WordPress          = 2
        static let Count        = 3
    }

    // MARK: - Private Constants
    private let emptyRowCount   = 0
    private let defaultRowCount = 1
    private let reuseIdentifier = "NotificationSettingsTableViewCell"
    
    // MARK: - Private Properties
    private var blogs : [Blog]?
}
