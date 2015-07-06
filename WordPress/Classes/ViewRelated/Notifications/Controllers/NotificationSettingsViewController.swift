import Foundation


public class NotificationSettingsViewController : UITableViewController
{
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Interface
        setupNavigationItem()
        setupTableView()
        
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
        title = NSLocalizedString("Notifications", comment: "Title displayed in the Notification settings")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .Plain, target: nil, action: nil)
    }
    
    private func setupTableView() {
        // Register the cells
        let reuseIdentifiers = [
            NoteSettingsTitleTableViewCell.classNameWithoutNamespaces(),
            NoteSettingsSubtitleTableViewCell.classNameWithoutNamespaces()
        ]
        
        for reuseIdentifier in reuseIdentifiers {
            let cellNib = UINib(nibName: reuseIdentifier, bundle: NSBundle.mainBundle())
            tableView.registerNib(cellNib, forCellReuseIdentifier: reuseIdentifier)
        }
        
        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()
        
        // Style!
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    
    // MARK: - Service Helpers
    private func reloadSettings() {
        let service = NotificationsService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        
// TODO: Spinner
        service.getAllSettings({ (settings: [NotificationSettings]) in
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



    // MARK: - UITableView Datasource Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return groupedSettings?.count ?? emptyCount
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedSettings?[section].count ?? emptyCount
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let settings    = settingsForRowAtIndexPath(indexPath)!
        let cell        = dequeueCellForSettings(settings, tableView: tableView)
        
        configureCell(cell, settings: settings)
        
        return cell
    }
    
    public override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch settingsForRowAtIndexPath(indexPath)!.channel {
        case let .Site(siteId):
            return subtitleRowHeight
        default:
            return titleRowHeight
        }
    }
    
    public override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        var frame           = CGRectZero
        frame.size.height   = seaparatorHeight
        return UIView(frame: frame)
    }


    // MARK: - UITableView Delegate Methods
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let settings = settingsForRowAtIndexPath(indexPath) {
            displayDetailsForSettings(settings)
        } else  {
            tableView.deselectSelectedRowWithAnimation(true)
        }
    }



    // MARK: - UITableView Helpers
    private func dequeueCellForSettings(settings: NotificationSettings, tableView: UITableView) -> UITableViewCell {
        let identifier : String
        
        switch settings.channel {
        case let .Site(siteId):
            identifier = NoteSettingsSubtitleTableViewCell.classNameWithoutNamespaces()
        default:
            identifier = NoteSettingsTitleTableViewCell.classNameWithoutNamespaces()
        }
        
        return tableView.dequeueReusableCellWithIdentifier(identifier) as! UITableViewCell
    }
    
    private func configureCell(cell: UITableViewCell, settings: NotificationSettings) {
        switch settings.channel {
        case let .Site(siteId):
            cell.textLabel?.text        = settings.blog?.blogName ?? settings.channel.description()
            cell.detailTextLabel?.text  = settings.blog?.displayURL ?? String()
            cell.imageView?.setImageWithSiteIcon(settings.blog?.icon)
        default:
            cell.textLabel?.text        = settings.channel.description()
        }
    }
    
    private func settingsForRowAtIndexPath(indexPath: NSIndexPath) -> NotificationSettings? {
        return groupedSettings?[indexPath.section][indexPath.row]
    }
    
    
    // MARK: - Segue Helpers
    private func displayDetailsForSettings(settings: NotificationSettings) {
        switch settings.channel {
        case .WordPressCom:
            // WordPress.com Row will push the SettingDetails ViewController, directly
            let detailsViewController = NotificationSettingDetailsViewController()
            detailsViewController.setupWithSettings(settings, streamAtIndex: firstStreamIndex)
            navigationController?.pushViewController(detailsViewController, animated: true)
        default:
            // Our Sites + 3rd Party Sites rows will push the Streams View
            let streamsViewController = NotificationSettingStreamsViewController()
            streamsViewController.setupWithSettings(settings)
            navigationController?.pushViewController(streamsViewController, animated: true)
        }
    }


    // MARK: - Private Constants
    private let titleRowHeight          = CGFloat(44.0)
    private let subtitleRowHeight       = CGFloat(54.0)
    private let emptyCount              = 0
    private let firstStreamIndex        = 0
    private let seaparatorHeight        = CGFloat(20.0)
    
    // MARK: - Private Properties
    private var groupedSettings         : [[NotificationSettings]]?
}
