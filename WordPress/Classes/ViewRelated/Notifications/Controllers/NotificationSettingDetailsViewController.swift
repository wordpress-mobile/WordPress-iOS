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
    private var sections = [SettingsSection]()

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
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: CellKind.Setting.rawValue)
        tableView.register(WPTableViewCellValue1.self, forCellReuseIdentifier: CellKind.Text.rawValue)

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
    private func sectionsForSettings(_ settings: NotificationSettings, stream: NotificationSettings.Stream) -> [SettingsSection] {
        // WordPress.com Channel requires a brief description per row.
        // For that reason, we'll render each row in its own section, with it's very own footer
        let singleSectionMode = settings.channel != .wordPressCom

        // Parse the Rows
        var rows = [SettingsRow]()

        for key in settings.sortedPreferenceKeys(stream) {
            let description = settings.localizedDescription(key)
            let value       = stream.preferences?[key] ?? true
            let row         = SwitchSettingsRow(kind: .Setting, description: description, key: key, value: value)

            rows.append(row)
        }

        // Single Section Mode: A single section will contain all of the rows
        if singleSectionMode {
            // Switch on stream type to provide descriptive text in footer for more context
            switch stream.kind {
            case .Device:
                if let blog = settings.blog {
                    // This should only be added for the device push notifications settings view
                    rows.append(TextSettingsRow(kind: .Text, description: NSLocalizedString("Blogging Reminders", comment: "Label for the blogging reminders setting"), value: schedule(for: blog), onTap: { [weak self] in
                        self?.presentBloggingRemindersFlow()
                    }))
                }

                return [SettingsSection(rows: rows, footerText: NSLocalizedString("Settings for push notifications that appear on your mobile device.", comment: "Descriptive text for the Push Notifications Settings"))]
            case .Email:
                return [SettingsSection(rows: rows, footerText: NSLocalizedString("Settings for notifications that are sent to the email tied to your account.", comment: "Descriptive text for the Email Notifications Settings"))]
            case .Timeline:
                return [SettingsSection(rows: rows, footerText: NSLocalizedString("Settings for notifications that appear in the Notifications tab.", comment: "Descriptive text for the Notifications Tab Settings"))]
            }
        }


        // Multi Section Mode: We'll have one Section per Row
        var sections = [SettingsSection]()

        for row in rows {
            let unwrappedKey    = row.key ?? String()
            let footerText      = settings.localizedDetails(unwrappedKey)
            let section         = SettingsSection(rows: [row], footerText: footerText)
            sections.append(section)
        }

        return sections
    }

    private func sectionsForDisabledDeviceStream() -> [SettingsSection] {
        let description     = NSLocalizedString("Go to iOS Settings", comment: "Opens WPiOS Settings.app Section")
        let row             = TextSettingsRow(kind: .Text, description: description, value: "")

        let footerText      = NSLocalizedString("Push Notifications have been turned off in iOS Settings App. " +
                                                "Toggle \"Allow Notifications\" to turn them back on.",
                                                comment: "Suggests to enable Push Notification Settings in Settings.app")
        let section         = SettingsSection(rows: [row], footerText: footerText)

        return [section]
    }

    private func sectionsForUnknownDeviceStream() -> [SettingsSection] {
        defer {
            WPAnalytics.track(.pushNotificationPrimerSeen, withProperties: [Analytics.locationKey: Analytics.alertKey])
        }
        let description     = NSLocalizedString("Allow push notifications", comment: "Shown to the user in settings when they haven't yet allowed or denied push notifications")
        let row             = TextSettingsRow(kind: .Text, description: description, value: "")

        let footerText      = NSLocalizedString("Allow WordPress to send you push notifications",
                                                comment: "Suggests the user allow push notifications. Appears within app settings.")
        let section         = SettingsSection(rows: [row], footerText: footerText)

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

        let section = sections[indexPath.section]

        if let row = section.rows[indexPath.row] as? TextSettingsRow,
           let onTap = row.onTap {
            onTap()
            return
        } else if isDeviceStreamDisabled() {
            openApplicationSettings()
        } else if isDeviceStreamUnknown() {
            requestNotificationAuthorization()
        }
    }


    // MARK: - UITableView Helpers
    private func configureTextCell(_ cell: WPTableViewCell, row: SettingsRow) {
        guard let row = row as? TextSettingsRow else {
            return
        }

        cell.textLabel?.text       = row.description
        cell.detailTextLabel?.text = row.value
        WPStyleGuide.configureTableViewCell(cell)
    }

    private func configureSwitchCell(_ cell: SwitchTableViewCell, row: SettingsRow) {
        guard let row = row as? SwitchSettingsRow else {
            return
        }

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
        InteractiveNotificationsManager.shared.requestAuthorization { [weak self] _ in
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

    // MARK: - Blogging Reminders

    func presentBloggingRemindersFlow() {
        guard let blog = settings?.blog else {
            return
        }

        BloggingRemindersFlow.present(from: self, for: blog, source: .notificationSettings) { [weak self] in
            self?.reloadTable()
        }
    }

    private func schedule(for blog: Blog) -> String {
        guard let scheduler = try? BloggingRemindersScheduler() else {
            return NSLocalizedString("None set", comment: "Title shown on table row where no blogging reminders have been set up yet")
        }

        let formatter = BloggingRemindersScheduleFormatter()
        return formatter.shortScheduleDescription(for: scheduler.schedule(for: blog), time: scheduler.scheduledTime(for: blog).toLocalTime()).string
    }

    private struct Analytics {
        static let locationKey = "location"
        static let alertKey = "settings"
    }
}

private enum CellKind: String {
    case Setting        = "SwitchCell"
    case Text           = "TextCell"
}

private protocol SettingsRow {
    var description: String { get }
    var kind: CellKind { get }
    var key: String? { get }
}

private struct SwitchSettingsRow: SettingsRow {
    let description: String
    let kind: CellKind
    let key: String?
    let value: Bool?

    init(kind: CellKind, description: String, key: String? = nil, value: Bool? = nil) {
        self.description    = description
        self.kind           = kind
        self.key            = key
        self.value          = value
    }
}

private struct TextSettingsRow: SettingsRow {
    let description: String
    let kind: CellKind
    let key: String? = nil
    let value: String
    let onTap: (() -> Void)?

    init(kind: CellKind, description: String, value: String, onTap: (() -> Void)? = nil) {
        self.description    = description
        self.kind           = kind
        self.value          = value
        self.onTap          = onTap
    }
}

private struct SettingsSection {
    var rows: [SettingsRow]
    var footerText: String?

    init(rows: [SettingsRow], footerText: String? = nil) {
        self.rows           = rows
        self.footerText     = footerText
    }
}
