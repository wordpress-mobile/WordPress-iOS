import Foundation


/**
*  @class           NotificationSettingDetailsViewController
*  @brief           The purpose of this class is to render a collection of NotificationSettings for a given
*                   Stream, encapsulated in the class NotificationSettings.Stream, and to provide the user
*                   a simple interface to update those settings, as needed.
*/

public class NotificationSettingDetailsViewController : UITableViewController
{
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNotifications()
        setupTableView()
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
    private func setupNotifications() {
        // Reload whenever the app becomes active again since Push Settings may have changed in the meantime!
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self,
            selector:   "reloadTable",
            name:       UIApplicationDidBecomeActiveNotification,
            object:     nil)
    }
    
    private func setupTableView() {
        // Register the cells
        tableView.registerClass(SwitchTableViewCell.self, forCellReuseIdentifier: switchIdentifier)
        tableView.registerClass(WPTableViewCell.self, forCellReuseIdentifier: defaultIdentifier)
        
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
    public func setupWithSettings(settings: NotificationSettings, stream: NotificationSettings.Stream) {
        // Setup the Title
        switch settings.channel {
        case .WordPressCom:
            title = NSLocalizedString("WordPress.com Updates", comment: "WordPress.com Notification Settings Title")
        default:
            title = stream.kind.description()
        }
        
        // Keep References
        self.settings   = settings
        self.stream     = stream
        
        // At last, reload!
        reloadTable()
    }

    public func reloadTable() {
        self.rows                 = rowsForSettings(settings!, stream: stream!)
        tableView.tableFooterView = isDeviceStreamDisabled() ? disabledDeviceStreamFooter() : UIView()
        tableView.reloadData()
    }
    
    

    // MARK: - Private Helpers
    private func rowsForSettings(settings: NotificationSettings, stream: NotificationSettings.Stream) -> [Row] {
        var rows = [Row]()
        for key in settings.sortedPreferenceKeys {
            let name    = settings.localizedDescription(key)
            let value   = stream.preferences?[key] ?? true
            
            rows.append(Row(name: name, key: key, value: value))
        }
        
        return rows
    }
    

    
    // MARK: - UITableView Delegate Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionCount
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isDeviceStreamDisabled() ? disabledRowCount : rows.count
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Disabled Push Notifications:
        // We'll render just one row, that should open Settings.app on press
        //
        if isDeviceStreamDisabled() {
            let cell                = tableView.dequeueReusableCellWithIdentifier(defaultIdentifier) as! WPTableViewCell
            cell.textLabel?.text    = NSLocalizedString("Go to iPhone Settings", comment: "Opens WPiOS Settings.app Section")
            WPStyleGuide.configureTableViewCell(cell)
            
            return cell
        }
        
        // Settings:
        // One SwitchCell per setting!
        //
        let cell = tableView.dequeueReusableCellWithIdentifier(switchIdentifier) as! SwitchTableViewCell
        configureSwitchCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)
        
        if isDeviceStreamDisabled() {
            openApplicationSettings()
        }
    }
    
    
    
    // MARK: - UITableView Helpers
    private func configureSwitchCell(cell: SwitchTableViewCell, indexPath: NSIndexPath) {
        let row         = rows[indexPath.row]
        
        cell.name       = row.name
        cell.isOn       = newValues[row.key] ?? (row.value ?? true)
        cell.onChange   = { [weak self] (newValue: Bool) in
            self?.newValues[row.key] = newValue
        }
    }
    
    
    
    // MARK: - Disabled Push Notifications Handling
    private func isDeviceStreamDisabled() -> Bool {
        return stream?.kind == .Device && !NotificationsManager.pushNotificationsEnabledInDeviceSettings()
    }
    
    private func disabledDeviceStreamFooter() -> UIView {
        let footerView      = WPTableViewSectionFooterView()
        footerView.title    = NSLocalizedString("Push Notifications have been turned off in iOS Settings App. " +
                                                "Toggle \"Allow Notifications\" to turn them back on.",
                                                comment: "Suggests to enable Push Notification Settings in Settings.app")
        
        return footerView
    }

    private func openApplicationSettings() {
        if !UIDevice.isOS8() {
            return
        }
        
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
        UIAlertView.showWithTitle(NSLocalizedString("Oops!", comment: ""),
            message             : NSLocalizedString("There has been an unexpected error while updating " +
                                                    "your Notification Settings",
                                                    comment: "Displayed after a failed Notification Settings call"),
            style               : .Default,
            cancelButtonTitle   : NSLocalizedString("Cancel", comment: "Cancel. Action."),
            otherButtonTitles   : [ NSLocalizedString("Retry", comment: "Retry. Action") ],
            tapBlock            : { (alertView: UIAlertView!, buttonIndex: Int) -> Void in
                if alertView.cancelButtonIndex == buttonIndex {
                    return
                }
                
                self.saveSettingsIfNeeded()
            })
    }
    
    
    
    // MARK: - Private Nested Class'ess
    private class Row {
        let name    : String
        let key     : String
        let value   : Bool
        
        init(name: String, key: String, value: Bool) {
            self.name   = name
            self.key    = key
            self.value  = value
        }
    }
    
    
    // MARK: - Private Constants
    private let defaultIdentifier   = WPTableViewCell.classNameWithoutNamespaces()
    private let switchIdentifier    = SwitchTableViewCell.classNameWithoutNamespaces()
    private let sectionCount        = 1
    private let disabledRowCount    = 1
    
    // MARK: - Private Properties
    private var settings            : NotificationSettings?
    private var stream              : NotificationSettings.Stream?
    
    // MARK: - Helpers
    private var rows                = [Row]()
    private var newValues           = [String: Bool]()
}
