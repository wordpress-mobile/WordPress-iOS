import Foundation
import WordPressShared
import WordPressComAnalytics


/// This class will simply render the collection of Streams available for a given NotificationSettings
/// collection.
/// A Stream represents a possible way in which notifications are communicated.
/// For instance: Push Notifications / WordPress.com Timeline / Email
///
open class NotificationSettingStreamsViewController: UITableViewController
{
    // MARK: - Initializers
    public convenience init(settings: NotificationSettings) {
        self.init(style: .grouped)
        setupWithSettings(settings)
    }



    // MARK: - View Lifecycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupNotifications()
        setupTableView()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Manually deselect the selected row. This is required due to a bug in iOS7 / iOS8
        tableView.deselectSelectedRowWithAnimation(true)
        WPAnalytics.track(.openedNotificationSettingStreams)
    }



    // MARK: - Setup Helpers
    fileprivate func setupNotifications() {
        // Reload whenever the app becomes active again since Push Settings may have changed in the meantime!
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
            selector:   #selector(NotificationSettingStreamsViewController.reloadTable),
            name:       NSNotification.Name.UIApplicationDidBecomeActive,
            object:     nil)
    }

    fileprivate func setupTableView() {
        // Empty Back Button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)

        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()

        // Style!
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }



    // MARK: - Public Helpers
    open func setupWithSettings(_ streamSettings: NotificationSettings) {
        // Title
        switch streamSettings.channel {
        case let .blog(blogId):
            _ = blogId
            title = streamSettings.blog?.settings?.name ?? streamSettings.channel.description()
        case .other:
            title = NSLocalizedString("Other Sites", comment: "Other Notifications Streams Title")
        default:
            // Note: WordPress.com is not expected here!
            break
        }

        // Structures
        settings       = streamSettings
        sortedStreams  = streamSettings.streams.sorted {  $0.kind.description() > $1.kind.description() }

        tableView.reloadData()
    }

    open func reloadTable() {
        tableView.reloadData()
    }



    // MARK: - UITableView Delegate Methods
    open override func numberOfSections(in tableView: UITableView) -> Int {
        return sortedStreams?.count ?? emptySectionCount
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowsCount
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? WPTableViewCell
        if cell == nil {
            cell = WPTableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)
        }

        configureCell(cell!, indexPath: indexPath)

        return cell!
    }

    open override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return footerForStream(streamAtSection(section))
    }

    open override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }



    // MARK: - UITableView Delegate Methods
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
    fileprivate func configureCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        let stream                  = streamAtSection(indexPath.section)
        let disabled                = isDisabledDeviceStream(stream)

        cell.imageView?.image       = imageForStreamKind(stream.kind)
        cell.imageView?.tintColor   = WPStyleGuide.greyLighten10()
        cell.textLabel?.text        = stream.kind.description()
        cell.detailTextLabel?.text  = disabled ? NSLocalizedString("Off", comment: "Disabled") : String()
        cell.accessoryType          = .disclosureIndicator

        WPStyleGuide.configureTableViewCell(cell)
    }

    fileprivate func streamAtSection(_ section: Int) -> NotificationSettings.Stream {
        return sortedStreams![section]
    }

    fileprivate func imageForStreamKind(_ streamKind: NotificationSettings.Stream.Kind) -> UIImage? {
        let imageName: String
        switch streamKind {
        case .Email:
            imageName = "notifications-email"
        case .Timeline:
            imageName = "notifications-bell"
        case .Device:
            imageName = "notifications-phone"
        }

        return UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
    }


    // MARK: - Disabled Push Notifications Helpers
    fileprivate func isDisabledDeviceStream(_ stream: NotificationSettings.Stream) -> Bool {
        return stream.kind == .Device && !PushNotificationsManager.sharedInstance.notificationsEnabledInDeviceSettings()
    }

    fileprivate func displayPushNotificationsAlert() {
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
    fileprivate func footerForStream(_ stream: NotificationSettings.Stream) -> String {
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
    fileprivate let reuseIdentifier     = WPTableViewCell.classNameWithoutNamespaces()
    fileprivate let emptySectionCount   = 0
    fileprivate let rowsCount           = 1

    // MARK: - Private Properties
    fileprivate var settings: NotificationSettings?
    fileprivate var sortedStreams: [NotificationSettings.Stream]?
}
