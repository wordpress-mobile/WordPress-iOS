import Foundation
import MGImageUtilities
import WordPressShared
import WordPressComAnalytics

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
        setupNotifications()
        setupTableView()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Manually deselect the selected row. This is required due to a bug in iOS7 / iOS8
        tableView.deselectSelectedRowWithAnimation(true)
        WPAnalytics.track(.OpenedNotificationSettingStreams)
    }


    
    // MARK: - Setup Helpers
    private func setupNotifications() {
        // Reload whenever the app becomes active again since Push Settings may have changed in the meantime!
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self,
            selector:   #selector(NotificationSettingStreamsViewController.reloadTable),
            name:       UIApplicationDidBecomeActiveNotification,
            object:     nil)
    }
    
    private func setupTableView() {
        // Empty Back Button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .Plain, target: nil, action: nil)
        
        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()
        
        // Style!
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)

        tableView.cellLayoutMarginsFollowReadableWidth = false
    }

    
    
    // MARK: - Public Helpers
    public func setupWithSettings(streamSettings: NotificationSettings) {
        // Title
        switch streamSettings.channel {
        case let .Blog(blogId):
            _ = blogId
            title = streamSettings.blog?.settings?.name ?? streamSettings.channel.description()
        case .Other:
            title = NSLocalizedString("Other Sites", comment: "Other Notifications Streams Title")
        default:
            // Note: WordPress.com is not expected here!
            break
        }
        
        // Structures
        settings       = streamSettings
        sortedStreams  = streamSettings.streams.sort {  $0.kind.description() > $1.kind.description() }
        
        tableView.reloadData()
    }
    
    public func reloadTable() {
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
        // iOS <8: Display the 'Enable Push Notifications Alert', when needed
        // iOS +8: Go ahead and push the details
        //
        let stream = streamAtSection(indexPath.section)
        
        if isDisabledDeviceStream(stream) && !UIDevice.isOS8() {
            tableView.deselectSelectedRowWithAnimation(true)
            displayPushNotificationsAlert()
            return
        }
        
        let detailsViewController = NotificationSettingDetailsViewController(settings: settings!, stream: stream)
        navigationController?.pushViewController(detailsViewController, animated: true)
    }
    
    
    
    // MARK: - Helpers
    private func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        let stream                  = streamAtSection(indexPath.section)
        let disabled                = isDisabledDeviceStream(stream)
        
        cell.imageView?.image       = imageForStreamKind(stream.kind)
        cell.textLabel?.text        = stream.kind.description() ?? String()
        cell.detailTextLabel?.text  = disabled ? NSLocalizedString("Off", comment: "Disabled") : String()
        cell.accessoryType          = .DisclosureIndicator
        
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    private func streamAtSection(section: Int) -> NotificationSettings.Stream {
        return sortedStreams![section]
    }
    
    private func imageForStreamKind(streamKind: NotificationSettings.Stream.Kind) -> UIImage? {
        let imageName : String
        switch streamKind {
        case .Email:
            imageName = "notifications-email"
        case .Timeline:
            imageName = "notifications-bell"
        case .Device:
            imageName = "notifications-phone"
        }
        
        let tintColor = WPStyleGuide.greyLighten10()
        return UIImage(named: imageName)?.imageTintedWithColor(tintColor)
    }
    
    
    // MARK: - Disabled Push Notifications Helpers
    private func isDisabledDeviceStream(stream: NotificationSettings.Stream) -> Bool {
        return stream.kind == .Device && !PushNotificationsManager.sharedInstance.notificationsEnabledInDeviceSettings()
    }
    
    private func displayPushNotificationsAlert() {
        let title   = NSLocalizedString("Push Notifications have been turned off in iOS Settings",
                                        comment: "Displayed when Push Notifications are disabled (iOS 7)")
        let message = NSLocalizedString("To enable notifications:\n\n" +
                                        "1. Open **iOS Settings**\n" +
                                        "2. Tap **Notifications**\n" +
                                        "3. Select **WordPress**\n" +
                                        "4. Turn on **Allow Notifications**",
                                        comment: "Displayed when Push Notifications are disabled (iOS 7)")
        let button = NSLocalizedString("Dismiss", comment: "Dismiss the AlertView")
        
        let alert = AlertView(title: title, message: message, button: button, completion: nil)
        alert.show()
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
