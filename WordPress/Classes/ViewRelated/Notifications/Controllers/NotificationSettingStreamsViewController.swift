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
        let detailsViewController = NotificationSettingDetailsViewController()
        detailsViewController.setupWithSettings(settings!, stream: settings!.streams[indexPath.row])
        navigationController?.pushViewController(detailsViewController, animated: true)
    }
    
    
    
    // MARK: - Helpers
    private func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        let stream                  = settings!.streams[indexPath.row]
        
        cell.textLabel?.text        = stream.kind.description() ?? String()
        cell.detailTextLabel?.text  = isStreamDisabled(stream) ? NSLocalizedString("Off", comment: "Disabled") : String()
        cell.accessoryType          = .DisclosureIndicator
        
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    private func isStreamDisabled(stream: NotificationSettings.Stream) -> Bool {
        return stream.kind == .Device && !NotificationsManager.pushNotificationsEnabledInDeviceSettings()
    }
    


    // MARK: - Private Constants
    private let reuseIdentifier = WPTableViewCell.classNameWithoutNamespaces()
    private let emptyRowCount   = 0
    private let sectionCount    = 1

    // MARK: - Private Properties
    private var settings        : NotificationSettings?
}
