import Foundation


public class NotificationSettingStreamsViewController : UITableViewController
{
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    
    
    // MARK: - Setup Helpers
    private func setupTableView() {
        // iPad Top header
        if UIDevice.isPad() {
            tableView.tableHeaderView = UIView(frame: WPTableHeaderPadFrame)
        }
        
        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()
        
        // Style!
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    
    
    // MARK: - Public Helpers
    public func setupWithSettings(settings: NotificationSettings) {
        self.settings = settings
        
        switch settings.channel {
        case let .Blog(blogId):
            title = settings.blog?.blogName ?? settings.channel.description()
        case .Other:
            title = NSLocalizedString("Other Sites", comment: "Other Notifications Streams Title")
        default:
            break
        }
        
        tableView.reloadData()
    }
    
    
    
    // MARK: - UITableView Delegate Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionCount
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings?.streams.count ?? emptyRowCount
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
            displayDisabledNotificationsView()
            return
        }
        
        let stream                  = settings?.streams[indexPath.row]
        let detailsViewController   = NotificationSettingDetailsViewController()
        
        detailsViewController.setupWithSettings(settings!, stream: stream!)
        navigationController?.pushViewController(detailsViewController, animated: true)
    }
    
    
    
    // MARK: - Helpers
    private func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        cell.textLabel?.text        = settings!.streams[indexPath.row].kind.description() ?? String()
        cell.detailTextLabel?.text  = isStreamEnabled(indexPath.row) ? String() : NSLocalizedString("Off", comment: "Disabled")
        cell.accessoryType          = .DisclosureIndicator
        
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    private func displayDisabledNotificationsView() {
// TODO!
    }
    
    private func isStreamEnabled(streamIndex: Int) -> Bool {
        switch settings!.streams[streamIndex].kind {
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
}
