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
    // MARK: - Initializers
    public convenience init(settings: NotificationSettings) {
        self.init(style: .Grouped)
        setupWithSettings(settings)
    }


    
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
        // Empty Back Button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .Plain, target: nil, action: nil)
        
        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()
        
        // Style!
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    
    
    // MARK: - Public Helpers
    public func setupWithSettings(streamSettings: NotificationSettings) {
        // Title
        switch streamSettings.channel {
        case let .Blog(blogId):
            title = streamSettings.blog?.blogName ?? streamSettings.channel.description()
        case .Other:
            title = NSLocalizedString("Other Sites", comment: "Other Notifications Streams Title")
        default:
            // Note: WordPress.com is not expected here!
            break
        }
        
        // Structures
        settings       = streamSettings
        sortedStreams  = streamSettings.streams.sorted { $0.kind.description() > $1.kind.description() }
        
        tableView.reloadData()
    }
    
    
    
    // MARK: - UITableView Delegate Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sortedStreams?.count ?? emptySectionCount
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowsCount
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as? WPTableViewCell
        if cell == nil {
            cell = WPTableViewCell(style: .Value1, reuseIdentifier: reuseIdentifier)
        }
        
        configureCell(cell!, indexPath: indexPath)
        
        return cell!
    }
    
    public override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let headerView = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Footer)
        headerView.title = footerForStream(streamAtSection(section))
        return headerView
    }
    
    public override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let title = footerForStream(streamAtSection(section))
        let width = view.frame.width
        return WPTableViewSectionHeaderFooterView.heightForFooter(title, width: width)
    }
    
    
    
    // MARK: - UITableView Delegate Methods
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let stream = streamAtSection(indexPath.section)
        
        if isDisabledDeviceStream(stream) {
            tableView.deselectSelectedRowWithAnimation(true)
            // NOTE: Disabled Streams will be handled in another PR!
            return
        }
        
        let detailsViewController = NotificationSettingDetailsViewController(settings: settings!, stream: stream)        
        navigationController?.pushViewController(detailsViewController, animated: true)
    }
    
    
    
    // MARK: - Helpers
    private func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        let stream                  = streamAtSection(indexPath.section)
        let disabled                = isDisabledDeviceStream(stream)
        
        cell.textLabel?.text        = stream.kind.description()
        cell.detailTextLabel?.text  = disabled ? NSLocalizedString("Off", comment: "Disabled") : String()
        cell.accessoryType          = .DisclosureIndicator
        
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    private func streamAtSection(section: Int) -> NotificationSettings.Stream {
        return sortedStreams![section]
    }
    
    
    
    // MARK: - Disabled Push Notifications Helpers
    private func isDisabledDeviceStream(stream: NotificationSettings.Stream) -> Bool {
        return stream.kind == .Device && !NotificationsManager.pushNotificationsEnabledInDeviceSettings()
    }

    
    
    // MARK: - Footers
    private func footerForStream(stream: NotificationSettings.Stream) -> String {
        switch stream.kind {
        case .Device:
            return NSLocalizedString("Settings for push notifications that appear on your mobile device.",
                comment: "Descriptive text for the Push Notifications Settings")
        case .Email:
            return NSLocalizedString("Settings for notifications that are sent to the email tied to your account.",
                comment: "Descriptive text for the Email Notifications Settings")
        case .Timeline:
            return NSLocalizedString("Settings for notifications that appear in the Notifications tab.",
                comment: "Descriptive text for the Notifications Tab Settings")
        }
    }
    
    
    
    // MARK: - Private Constants
    private let reuseIdentifier     = WPTableViewCell.classNameWithoutNamespaces()
    private let emptySectionCount   = 0
    private let rowsCount           = 1

    // MARK: - Private Properties
    private var settings        : NotificationSettings?
    private var sortedStreams   : [NotificationSettings.Stream]?
}
