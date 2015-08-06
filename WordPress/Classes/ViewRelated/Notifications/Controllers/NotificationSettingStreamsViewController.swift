import Foundation


/**
*  @class           NotificationSettingStreamsViewController
*  @brief           This class will simply render the collection of Streams available for a given
*                   NotificationSettings collection.
*                   A Stream represents a possible way in which notifications are communicated.
*                   For instance: Push Notifications / WordPress.com Timeline / Email
*/

public class NotificationSettingStreamsViewController : UITableViewController
{
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Manually deselect the selected row. This is required due to a bug in iOS7 / iOS8
        tableView.deselectSelectedRowWithAnimation(true)
    }
    
    
    
    // MARK: - Setup Helpers
    private func setupTableView() {
        // iPad Top header
        if UIDevice.isPad() {
            tableView.tableHeaderView = UIView(frame: WPTableHeaderPadFrame)
        }
        
        // Empty Back Button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .Plain, target: nil, action: nil)
        
        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()
        
        // Style!
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    
    
    // MARK: - Public Helpers
    public func setupWithSettings(settings: NotificationSettings) {
        // Title
        switch settings.channel {
        case let .Blog(blogId):
            title = settings.blog?.blogName ?? settings.channel.description()
        case .Other:
            title = NSLocalizedString("Other Sites", comment: "Other Notifications Streams Title")
        default:
            // Note: WordPress.com is not expected here!
            break
        }
        
        // Structures
        self.settings       = settings
        self.sortedStreams  = settings.streams.sorted { $0.kind.description() > $1.kind.description() }
        
        tableView.reloadData()
    }
    
    
    
    // MARK: - UITableView Delegate Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionCount
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedStreams?.count ?? emptyRowCount
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as? WPTableViewCell
        if cell == nil {
            cell = WPTableViewCell(style: .Value1, reuseIdentifier: reuseIdentifier)
        }
        
        configureCell(cell!, indexPath: indexPath)
        
        return cell!
    }
    
    
    
    // MARK: - UITableView Delegate Methods
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !isStreamEnabled(indexPath.row) {
            tableView.deselectSelectedRowWithAnimation(true)
            // NOTE: This will be addressed in another PR!
            return
        }
        
        let detailsViewController = NotificationSettingDetailsViewController()
        detailsViewController.setupWithSettings(settings!, stream: sortedStreams![indexPath.row])
        
        navigationController?.pushViewController(detailsViewController, animated: true)
    }
    
    
    
    // MARK: - Helpers
    private func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        cell.textLabel?.text        = sortedStreams?[indexPath.row].kind.description() ?? String()
        cell.detailTextLabel?.text  = isStreamEnabled(indexPath.row) ? String() : NSLocalizedString("Off", comment: "Disabled")
        cell.accessoryType          = .DisclosureIndicator
        
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    private func isStreamEnabled(streamIndex: Int) -> Bool {
        switch sortedStreams![streamIndex].kind {
        case .Device:
            return NotificationsManager.pushNotificationsEnabledInDeviceSettings()
        default:
            return true
        }
    }

    
    
    // MARK: - Private Constants
    private let reuseIdentifier = WPTableViewCell.classNameWithoutNamespaces()
    private let emptyRowCount   = 0
    private let sectionCount    = 1

    // MARK: - Private Properties
    private var settings        : NotificationSettings?
    private var sortedStreams   : [NotificationSettings.Stream]?
}
