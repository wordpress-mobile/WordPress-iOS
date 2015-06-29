import Foundation


public class NotificationSettingSectionsViewController : UITableViewController
{
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Settings", comment: "Title displayed in the Notification settings")
        
        setupServices()
        setupDismissButton()
        reloadBlogsList()
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
        if section == Section.Blog.rawValue {
            return blogs?.count ?? emptyRowCount
        }

        return defaultRowCount
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
    private func setupServices() {
        let mainContext         = ContextManager.sharedInstance().mainContext
        blogService             = BlogService(managedObjectContext: mainContext)
        notificationsService    = NotificationsService(managedObjectContext: mainContext)
    }
    
    private func setupDismissButton() {
        let title  = NSLocalizedString("Close", comment: "Close the currrent screen. Action")
        let action = Selector("dismissWasPressed:")

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: title, style: .Plain, target: self, action: action)
    }

    private func reloadBlogsList() {
// TODO: Filter only dotcom and jetpack maybe?
        if let unwrappedBlogs = blogService.blogsForAllAccounts() as? [Blog] {
            blogs = unwrappedBlogs
        }
    }


    // MARK: - Button Handlers
    private func blogWasPressed(blog: Blog?) {
        let blogId = blog!.blogID as? Int
        if blogId == nil {
            return
        }
        
        notificationsService.getSiteSettings(blogId!,
            success: {
                (settings: [NotificationSettings.Site]) in
            },
            failure: {
                (error: NSError!) in
            })
    }
    
    private func otherWasPressed() {
        notificationsService.getOtherSettings({
                (settings: [NotificationSettings.Other]) in
            
            },
            failure: {
                (error: NSError!) in
            })
    }
    
    private func wordPressWasPressed() {
        notificationsService.getWordPressComSettings({
                (wpcom: NotificationSettings.WordPressCom) in

            },
            failure: {
                (error: NSError!) in
            })
    }

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
    private var blogService             : BlogService!
    private var notificationsService    : NotificationsService!
}
