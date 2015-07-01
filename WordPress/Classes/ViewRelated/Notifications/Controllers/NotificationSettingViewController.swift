import Foundation


public class NotificationSettingViewController : UITableViewController
{
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Interface
        setupNavigationItem()
        setupTableView()
        
        // Load Blogs + Settings
        reloadBlogs()
        reloadSettings()
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
    private func reloadBlogs() {
// TODO: Filter
        let service = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        if let allBlogs = service.blogsForAllAccounts() as? [Blog] {
            blogs = allBlogs
        }
    }
    
    private func reloadSettings() {
// TODO: Spinner
println("Loading")
        let service = NotificationsService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.getAllSettings({ (settings: [NotificationSettings]) in
println("Loaded!")
                self.settings = settings
            },
            failure: { (error: NSError!) in
println("Error \(error)")
            })
    }



    // MARK: - UITableView Delegate Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return NotificationSettings.Channel.allValues.count
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch channelForSection(section) {
        case .Site:
            return blogs?.count ?? emptyRowCount
        default:
            return defaultRowCount
        }
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! UITableViewCell
        
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }



    // MARK: - UITableView Delegate Methods
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let settings = settingsForRowAtIndexPath(indexPath) {
            let identifier = destinationSegueIdentifier(indexPath)
            performSegueWithIdentifier(identifier, sender: settings)
        } else {
            tableView.deselectSelectedRowWithAnimation(true)
        }
    }



    // MARK: - UITableView Helpers
    private func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        let description : String
        let channel = channelForSection(indexPath.section)
        
        switch channel {
        case .Site:
            description = blogs?[indexPath.row].blogName ?? channel.description()
        default:
            description = channel.description()
        }
        
        cell.textLabel?.text = description
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    private func destinationSegueIdentifier(indexPath: NSIndexPath) -> String {
        // WordPress.com Row will push the SettingDetails ViewController, directly
        if channelForSection(indexPath.section) == .WordPressCom {
            return NotificationSettingDetailsViewController.classNameWithoutNamespaces()
        }
        
        // Our Sites + 3rd Party Sites rows will push the Streams View
        return NotificationSettingStreamsViewController.classNameWithoutNamespaces()
    }
    
    private func settingsForRowAtIndexPath(indexPath: NSIndexPath) -> NotificationSettings? {
// TODO: Fix This
        var targetChannel = channelForSection(indexPath.section)
        
        switch targetChannel {
        case .Site:
            if let siteId = blogAtRow(indexPath.row)?.blogID?.integerValue {
                targetChannel = NotificationSettings.Channel.Site(siteId: siteId)
            }
        default:
println("")
        }
        
        let filtered = settings?.filter { $0.channel == targetChannel }
        return filtered?.first
    }
    
    private func channelForSection(section: Int) -> NotificationSettings.Channel {
        return NotificationSettings.Channel.allValues[section]
    }
    
    private func blogAtRow(row: Int) -> Blog? {
        return blogs?[row]
    }
    
    
    // MARK: - Segue Helpers
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let targetSettings = sender as? NotificationSettings
        if targetSettings == nil {
            return
        }
        
        if let streamsViewController = segue.destinationViewController as? NotificationSettingStreamsViewController {
            streamsViewController.setupWithSettings(targetSettings!)
            
        } else if let detailsViewController = segue.destinationViewController as? NotificationSettingDetailsViewController {
// TODO: Fixme
            detailsViewController.setupWithSettings(targetSettings!, streamAtIndex: 0)
        }
    }


    // MARK: - Button Handlers
    public func dismissWasPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }


    // MARK: - Private Constants
    private let emptyRowCount   = 0
    private let defaultRowCount = 1
    private let reuseIdentifier = "NotificationSettingsTableViewCell"
    
    // MARK: - Private Properties
    private var blogs           : [Blog]?
    private var settings        : [NotificationSettings]?
}
