import Foundation
import WordPressShared
import UserNotifications


/// The purpose of this class is to render a collection of NotificationSettings for a given Stream,
/// encapsulated in the class NotificationSettings.Stream, and to provide the user a simple interface
/// to update those settings, as needed.
///
class NotificationSettingDetailsViewController: UITableViewController {

    /// Index of the very first tableVIew Section
    ///
    private let firstSectionIndex = 0

    /// NotificationSettings being rendered
    ///
    private var settings: NotificationSettings?

    /// Notification Stream to be displayed
    ///
    private var stream: NotificationSettings.Stream?

    /// TableView Sections to be rendered
    ///
    private var sections = [Section]()

    /// Contains all of the updated Stream Settings
    ///
    private var newValues = [String: Bool]()

    /// Indicates whether push notifications have been disabled, in the device, or not.
    ///
    private var pushNotificationsAuthorized: UNAuthorizationStatus = .notDetermined {
        didSet {
            reloadTable()
        }
    }

    /// Returns the name of the current site, if any
    ///
    private var siteName: String {
        switch settings!.channel {
        case .wordPressCom:
            return NSLocalizedString("WordPress.com Updates", comment: "WordPress.com Notification Settings Title")
        case .other:
            return NSLocalizedString("Other Sites", comment: "Other Sites Notification Settings Title")
        default:
            return settings?.blog?.settings?.name ?? NSLocalizedString("Unnamed Site", comment: "Displayed when a site has no name")
        }
    }



    convenience init(settings: NotificationSettings) {
        self.init(settings: settings, stream: settings.streams.first!)
    }

    convenience init(settings: NotificationSettings, stream: NotificationSettings.Stream) {
        self.init(style: .grouped)
        self.settings = settings
        self.stream = stream
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTitle()
        setupTableView()
        reloadTable()

        startListeningToNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refreshPushAuthorizationStatus()
        WPAnalytics.track(.openedNotificationSettingDetails)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        saveSettingsIfNeeded()
    }


    // MARK: - Setup Helpers
    private func startListeningToNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(refreshPushAuthorizationStatus), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    private func setupTitle() {
        title = stream?.kind.description()
    }

    private func setupTableView() {
        // Register the cells
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: Row.Kind.Setting.rawValue)
        tableView.register(WPTableViewCell.self, forCellReuseIdentifier: Row.Kind.Text.rawValue)

        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()

        // Style!
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    @IBAction func reloadTable() {
        if isDeviceStreamDisabled() {
            sections = sectionsForDisabledDeviceStream()
        } else if isDeviceStreamUnknown() {
            sections = sectionsForUnknownDeviceStream()
        } else if let settings = settings, let stream = stream {
            sections = sectionsForSettings(settings, stream: stream)
        }
        tableView.reloadData()
    }


    // MARK: - Private Helpers
    private func sectionsForSettings(_ settings: NotificationSettings, stream: NotificationSettings.Stream) -> [Section] {
        // WordPress.com Channel requires a brief description per row.
        // For that reason, we'll render each row in its own section, with it's very own footer
        let singleSectionMode = settings.channel != .wordPressCom

        // Parse the Rows
        var rows = [Row]()

        for key in settings.sortedPreferenceKeys(stream) {
            let description = settings.localizedDescription(key)
            let value       = stream.preferences?[key] ?? true
            let row         = Row(kind: .Setting, description: description, key: key, value: value)

            rows.append(row)
        }

        // Single Section Mode: A single section will contain all of the rows
        if singleSectionMode {
            return [Section(rows: rows)]
        }

        // Multi Section Mode: We'll have one Section per Row
        var sections = [Section]()

        for row in rows {
            let unwrappedKey    = row.key ?? String()
            let footerText      = settings.localizedDetails(unwrappedKey)
            let section         = Section(rows: [row], footerText: footerText)
            sections.append(section)
        }

        return sections
    }

    private func sectionsForDisabledDeviceStream() -> [Section] {
        let description     = NSLocalizedString("Go to iOS Settings", comment: "Opens WPiOS Settings.app Section")
        let row             = Row(kind: .Text, description: description, key: nil, value: nil)

        let footerText      = NSLocalizedString("Push Notifications have been turned off in iOS Settings App. " +
                                                "Toggle \"Allow Notifications\" to turn them back on.",
                                                comment: "Suggests to enable Push Notification Settings in Settings.app")
        let section         = Section(rows: [row], footerText: footerText)

        return [section]
    }

    private func sectionsForUnknownDeviceStream() -> [Section] {
        defer {
            WPAnalytics.track(.pushNotificationPrimerSeen, withProperties: [Analytics.locationKey: Analytics.alertKey])
        }
        let description     = NSLocalizedString("Allow push notifications", comment: "Shown to the user in settings when they haven't yet allowed or denied push notifications")
        let row             = Row(kind: .Text, description: description, key: nil, value: nil)

        let footerText      = NSLocalizedString("Allow WordPress to send you push notifications",
                                                comment: "Suggests the user allow push notifications. Appears within app settings.")
        let section         = Section(rows: [row], footerText: footerText)

        return [section]
    }


    // MARK: - UITableView Delegate Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let row     = section.rows[indexPath.row]
        let cell    = tableView.dequeueReusableCell(withIdentifier: row.kind.rawValue)

        switch row.kind {
        case .Text:
            configureTextCell(cell as! WPTableViewCell, row: row)
        case .Setting:
            configureSwitchCell(cell as! SwitchTableViewCell, row: row)
        }

        return cell!
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section == firstSectionIndex else {
            return nil
        }
        return siteName
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footerText
    }

    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)

        if isDeviceStreamDisabled() {
            openApplicationSettings()
        } else if isDeviceStreamUnknown() {
            requestNotificationAuthorization()
        }
    }


    // MARK: - UITableView Helpers
    private func configureTextCell(_ cell: WPTableViewCell, row: Row) {
        cell.textLabel?.text    = row.description
        WPStyleGuide.configureTableViewCell(cell)
    }

    private func configureSwitchCell(_ cell: SwitchTableViewCell, row: Row) {
        let settingKey          = row.key ?? String()

        cell.name               = row.description
        cell.on                 = newValues[settingKey] ?? (row.value ?? true)
        cell.onChange           = { [weak self] (newValue: Bool) in
            self?.newValues[settingKey] = newValue
        }
    }


    // MARK: - Disabled Push Notifications Handling
    private func isDeviceStreamDisabled() -> Bool {
        return stream?.kind == .Device && pushNotificationsAuthorized == .denied
    }

    private func isDeviceStreamUnknown() -> Bool {
        return stream?.kind == .Device && pushNotificationsAuthorized == .notDetermined
    }

    private func openApplicationSettings() {
        let targetURL = URL(string: UIApplication.openSettingsURLString)
        UIApplication.shared.open(targetURL!)
    }

    private func requestNotificationAuthorization() {
        defer {
            WPAnalytics.track(.pushNotificationPrimerAllowTapped, withProperties: [Analytics.locationKey: Analytics.alertKey])
        }
        InteractiveNotificationsManager.shared.requestAuthorization { [weak self] in
            self?.refreshPushAuthorizationStatus()
        }
    }

    @objc func refreshPushAuthorizationStatus() {
        PushNotificationsManager.shared.loadAuthorizationStatus { status in
            self.pushNotificationsAuthorized = status
        }
    }


    // MARK: - Service Helpers
    private func saveSettingsIfNeeded() {
        if newValues.count == 0 || settings == nil {
            return
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = NotificationSettingsService(managedObjectContext: context)

        service.updateSettings(settings!,
            stream: stream!,
            newValues: newValues,
            success: {
                WPAnalytics.track(.notificationsSettingsUpdated, withProperties: ["success": true])
            },
            failure: { (error: Error?) in
                WPAnalytics.track(.notificationsSettingsUpdated, withProperties: ["success": false])
                self.handleUpdateError()
            })
    }

    private func handleUpdateError() {
        let title       = NSLocalizedString("Oops!", comment: "An informal exclaimation meaning `something went wrong`.")
        let message     = NSLocalizedString("There has been an unexpected error while updating your Notification Settings",
                                            comment: "Displayed after a failed Notification Settings call")
        let cancelText  = NSLocalizedString("Cancel", comment: "Cancel. Action.")
        let retryText   = NSLocalizedString("Retry", comment: "Retry. Action")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alertController.addCancelActionWithTitle(cancelText, handler: nil)

        alertController.addDefaultActionWithTitle(retryText) { (action: UIAlertAction) in
            self.saveSettingsIfNeeded()
        }

        alertController.presentFromRootViewController()
    }


    // MARK: - Private Nested Class'ess
    private class Section {
        var rows: [Row]
        var footerText: String?

        init(rows: [Row], footerText: String? = nil) {
            self.rows           = rows
            self.footerText     = footerText
        }
    }

    private class Row {
        let description: String
        let kind: Kind
        let key: String?
        let value: Bool?

        init(kind: Kind, description: String, key: String? = nil, value: Bool? = nil) {
            self.description    = description
            self.kind           = kind
            self.key            = key
            self.value          = value
        }

        enum Kind: String {
            case Setting        = "SwitchCell"
            case Text           = "TextCell"
        }
    }

    private struct Analytics {
        static let locationKey = "location"
        static let alertKey = "settings"
    }
}
