import Foundation


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
        self.init(style: .Grouped)
        setupWithSettings(settings, stream: settings.streams.first!)
    }
    
    public convenience init(settings: NotificationSettings, stream: NotificationSettings.Stream) {
        self.init(style: .Grouped)
        setupWithSettings(settings, stream: stream)
    }
    
    
    
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        saveSettingsIfNeeded()
    }
    
    
    
    // MARK: - Setup Helpers
    private func setupTableView() {
        // Register the cells
        tableView.registerClass(SwitchTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
                
        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()
        
        // Style!
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    
    
    // MARK: - Public Helpers
    public func setupWithSettings(settings: NotificationSettings, stream: NotificationSettings.Stream) {
        // Title
        switch settings.channel {
        case .WordPressCom:
            title = NSLocalizedString("WordPress.com Updates", comment: "WordPress.com Notification Settings Title")
        default:
            title = stream.kind.description()
        }
        
        // Structures
        self.settings   = settings
        self.stream     = stream
        self.newValues  = [String: Bool]()
        
        tableView.reloadData()
    }
    
    
    
    // MARK: - UITableView Delegate Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionCount
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings?.sortedPreferenceKeys(stream).count ?? emptyRowCount
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! SwitchTableViewCell
        
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    
    
    // MARK: - UITableView Helpers
    private func configureCell(cell: SwitchTableViewCell, indexPath: NSIndexPath) {
        let preferences         = stream?.preferences
        let sortedKeys          = settings?.sortedPreferenceKeys(stream)
        let key                 = sortedKeys?[indexPath.row]
        if preferences == nil || key == nil {
            return
        }
        
        cell.name               = settings?.localizedDescription(key!) ?? String()
        cell.on                 = preferences?[key!] ?? true
        cell.onChange           = { [weak self] (newValue: Bool) in
            self?.newValues?[key!] = newValue
        }
    }
    
    
    
    // MARK: - Service Helpers
    private func saveSettingsIfNeeded() {
        if newValues?.count == 0 || settings == nil {
            return
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = NotificationsService(managedObjectContext: context)
                
        service.updateSettings(settings!,
            stream              : stream!,
            newValues           : newValues!,
            success             : nil,
            failure             : { (error: NSError!) in
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
    
    
    
    // MARK: - Private Constants
    private let reuseIdentifier     = SwitchTableViewCell.classNameWithoutNamespaces()
    private let emptyRowCount       = 0
    private let sectionCount        = 1
    
    // MARK: - Private Properties
    private var settings            : NotificationSettings?
    private var stream              : NotificationSettings.Stream?
    private var newValues           : [String: Bool]?
}
