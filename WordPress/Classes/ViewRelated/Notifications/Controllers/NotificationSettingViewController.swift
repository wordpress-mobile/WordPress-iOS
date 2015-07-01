import Foundation


public class NotificationSettingViewController : UITableViewController
{
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Interface
        setupNavigationItem()
        setupTableView()
        setupServices()
        
        // Load Settings
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
    
    private func setupServices() {
        let contextManager      = ContextManager.sharedInstance().mainContext
        blogService             = BlogService(managedObjectContext: contextManager)
        notificationsService    = NotificationsService(managedObjectContext: contextManager)
    }
    
    
    // MARK: - Service Helpers
    private func reloadSettings() {
// TODO: Spinner
        notificationsService?.getAllSettings({ (settings: [NotificationSettings]) in
                self.groupedSettings = self.groupSettings(settings)
                self.tableView.reloadData()
            },
            failure: { (error: NSError!) in
// TODO: Handle Error
println("Error \(error)")
            })
    }
    
    private func groupSettings(settings: [NotificationSettings]) -> [[NotificationSettings]] {
        // TODO: Review this whenever we switch to Swift 2.0, and kill the switch filtering. JLP Jul.1.2015
        let siteSettings = settings.filter {
            switch $0.channel {
            case .Site:
                return true
            default:
                return false
            }
        }
        
        let otherSettings = settings.filter { $0.channel == .Other }
        let wpcomSettings = settings.filter { $0.channel == .WordPressCom }
        
        return [siteSettings, otherSettings, wpcomSettings]
    }



    // MARK: - UITableView Delegate Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return groupedSettings?.count ?? emptyCount
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedSettings?[section].count ?? emptyCount
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! UITableViewCell
        
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }



    // MARK: - UITableView Delegate Methods
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let settings = settingsForRowAtIndexPath(indexPath)
        if settings == nil {
            tableView.deselectSelectedRowWithAnimation(true)
            return
        }

        let identifier = destinationSegueIdentifier(indexPath)
        performSegueWithIdentifier(identifier, sender: settings)
    }



    // MARK: - UITableView Helpers
    private func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        let channel = settingsForRowAtIndexPath(indexPath)?.channel
        var description : String?
        
        if channel == nil {
            return
        }
        
        switch channel! {
        case let .Site(siteId):
            description = blogService?.blogByBlogId(siteId)?.blogName
        default:
            break
        }
        
        cell.textLabel?.text = description ?? channel!.description()
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    private func destinationSegueIdentifier(indexPath: NSIndexPath) -> String {
        switch settingsForRowAtIndexPath(indexPath)!.channel {
        case .WordPressCom:
            // WordPress.com Row will push the SettingDetails ViewController, directly
            return NotificationSettingDetailsViewController.classNameWithoutNamespaces()
        default:
            // Our Sites + 3rd Party Sites rows will push the Streams View
            return NotificationSettingStreamsViewController.classNameWithoutNamespaces()
        }
    }
    
    private func settingsForRowAtIndexPath(indexPath: NSIndexPath) -> NotificationSettings? {
        return groupedSettings?[indexPath.section][indexPath.row]
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
            detailsViewController.setupWithSettings(targetSettings!, streamAtIndex: firstStreamIndex)
        }
    }


    // MARK: - Button Handlers
    public func dismissWasPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }


    // MARK: - Private Constants
    private let emptyCount              = 0
    private let firstStreamIndex        = 0
    private let reuseIdentifier         = "NotificationSettingsTableViewCell"
    
    // MARK: - Private Properties
    private var blogService             : BlogService?
    private var notificationsService    : NotificationsService?
    private var groupedSettings         : [[NotificationSettings]]?
}
