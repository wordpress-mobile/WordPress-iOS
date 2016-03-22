import Foundation
import WordPressShared
import WordPressComAnalytics

/**
*  @class           NotificationSettingDetailsViewController
*  @brief           The purpose of this class is to render a collection of NotificationSettings for a given
*                   Stream, encapsulated in the class NotificationSettings.Stream, and to provide the user
*                   a simple interface to update those settings, as needed.
*/

public class NotificationSettingDetailsViewController : UITableViewController
{
    // MARK: - Initializers
    public convenience init(settings: NotificationSettings) {
        self.init(settings: settings, stream: settings.streams.first!)
    }
    
    public convenience init(settings: NotificationSettings, stream: NotificationSettings.Stream) {
        self.init(style: .Grouped)
        self.settings = settings
        self.stream = stream
    }
    
    
    
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTitle()
        setupNotifications()
        setupTableView()
        reloadTable()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        WPAnalytics.track(.OpenedNotificationSettingDetails)
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        saveSettingsIfNeeded()
    }
    
    
    
    // MARK: - Setup Helpers
    private func setupTitle() {
        title = stream?.kind.description()
    }
    
    private func setupNotifications() {
        // Reload whenever the app becomes active again since Push Settings may have changed in the meantime!
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self,
            selector:   #selector(NotificationSettingDetailsViewController.reloadTable),
            name:       UIApplicationDidBecomeActiveNotification,
            object:     nil)
    }
    
    private func setupTableView() {
        // Register the cells
        tableView.registerClass(SwitchTableViewCell.self, forCellReuseIdentifier: Row.Kind.Setting.rawValue)
        tableView.registerClass(WPTableViewCell.self, forCellReuseIdentifier: Row.Kind.Text.rawValue)
        
        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()
        
        // Style!
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)

        tableView.cellLayoutMarginsFollowReadableWidth = false
    }

    @IBAction func reloadTable() {
        sections = isDeviceStreamDisabled() ? sectionsForDisabledDeviceStream() : sectionsForSettings(settings!, stream: stream!)
        tableView.reloadData()
    }

    

    // MARK: - Private Helpers
    private func sectionsForSettings(settings: NotificationSettings, stream: NotificationSettings.Stream) -> [Section] {
        // WordPress.com Channel requires a brief description per row.
        // For that reason, we'll render each row in its own section, with it's very own footer
        let singleSectionMode = settings.channel != .WordPressCom
        
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
    

    
    // MARK: - UITableView Delegate Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let row     = section.rows[indexPath.row]
        let cell    = tableView.dequeueReusableCellWithIdentifier(row.kind.rawValue)
        
        switch row.kind {
        case .Text:
            configureTextCell(cell as! WPTableViewCell, row: row)
        case .Setting:
            configureSwitchCell(cell as! SwitchTableViewCell, row: row)
        }
        
        return cell!
    }

    public override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == firstSectionIndex else {
            return 0
        }
        
        return WPTableViewSectionHeaderFooterView.heightForHeader(siteName, width: view.bounds.width)
    }
    
    public override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == firstSectionIndex else {
            return nil
        }
        
        let headerView      = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Header)
        headerView.title    = siteName
        return headerView
    }
    
    public override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let footerText = sections[section].footerText else {
            return CGFloat.min
        }

        return WPTableViewSectionHeaderFooterView.heightForFooter(footerText, width: view.bounds.width)
    }
    
    public override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerText = sections[section].footerText else {
            return nil
        }
        
        let footerView      = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Footer)
        footerView.title    = footerText
        return footerView
    }
    
    
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)
        
        if isDeviceStreamDisabled() {
            openApplicationSettings()
        }
    }
    
    
    
    // MARK: - UITableView Helpers
    private func configureTextCell(cell: WPTableViewCell, row: Row) {
        cell.textLabel?.text    = row.description
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    private func configureSwitchCell(cell: SwitchTableViewCell, row: Row) {
        let settingKey          = row.key ?? String()
        
        cell.name               = row.description
        cell.on                 = newValues[settingKey] ?? (row.value ?? true)
        cell.onChange           = { [weak self] (newValue: Bool) in
            self?.newValues[settingKey] = newValue
        }
    }
    
    
    
    // MARK: - Disabled Push Notifications Handling
    private func isDeviceStreamDisabled() -> Bool {
        return stream?.kind == .Device && !PushNotificationsManager.sharedInstance.notificationsEnabledInDeviceSettings()
    }
    
    private func openApplicationSettings() {
        let targetURL = NSURL(string: UIApplicationOpenSettingsURLString)
        UIApplication.sharedApplication().openURL(targetURL!)
    }
    
    
    
    // MARK: - Service Helpers
    private func saveSettingsIfNeeded() {
        if newValues.count == 0 || settings == nil {
            return
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = NotificationsService(managedObjectContext: context)
                
        service.updateSettings(settings!,
            stream              : stream!,
            newValues           : newValues,
            success             : {
                WPAnalytics.track(.NotificationsSettingsUpdated, withProperties: ["success" : true])
            },
            failure             : { (error: NSError!) in
                WPAnalytics.track(.NotificationsSettingsUpdated, withProperties: ["success" : false])
                self.handleUpdateError()
            })
    }
    
    private func handleUpdateError() {
        let title       = NSLocalizedString("Oops!", comment: "")
        let message     = NSLocalizedString("There has been an unexpected error while updating your Notification Settings",
                                            comment: "Displayed after a failed Notification Settings call")
        let cancelText  = NSLocalizedString("Cancel", comment: "Cancel. Action.")
        let retryText   = NSLocalizedString("Retry", comment: "Retry. Action")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        alertController.addCancelActionWithTitle(cancelText, handler: nil)
        
        alertController.addDefaultActionWithTitle(retryText) { (action: UIAlertAction) in
            self.saveSettingsIfNeeded()
        }
        
        alertController.presentFromRootViewController()
    }
    
    
    
    // MARK: - Private Nested Class'ess
    private class Section {
        var rows                : [Row]
        var footerText          : String?
        
        init(rows: [Row], footerText: String? = nil) {
            self.rows           = rows
            self.footerText     = footerText
        }
    }
    
    private class Row {
        let description         : String
        let kind                : Kind
        let key                 : String?
        let value               : Bool?
        
        init(kind: Kind, description: String, key: String? = nil, value: Bool? = nil) {
            self.description    = description
            self.kind           = kind
            self.key            = key
            self.value          = value
        }
        
        enum Kind : String {
            case Setting        = "SwitchCell"
            case Text           = "TextCell"
        }
    }
    

    // MARK: - Computed Properties
    private var siteName : String {
        switch settings!.channel {
        case .WordPressCom:
            return NSLocalizedString("WordPress.com Updates", comment: "WordPress.com Notification Settings Title")
        case .Other:
            return NSLocalizedString("Other Sites", comment: "Other Sites Notification Settings Title")
        default:
            return settings?.blog?.settings?.name ?? NSLocalizedString("Unnamed Site", comment: "Displayed when a site has no name")
        }
    }

    // MARK: - Private Constants
    private let firstSectionIndex = 0
    
    // MARK: - Private Properties
    private var settings : NotificationSettings?
    private var stream : NotificationSettings.Stream?
    
    // MARK: - Helpers
    private var sections = [Section]()
    private var newValues = [String: Bool]()
}
