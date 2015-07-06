import Foundation


public class NotificationSettingDetailsViewController : UITableViewController
{
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
        let reuseIdentifier = NoteSettingsSwitchTableViewCell.classNameWithoutNamespaces()
        let switchCellNib   = UINib(nibName: reuseIdentifier, bundle: NSBundle.mainBundle())
        tableView.registerNib(switchCellNib, forCellReuseIdentifier: reuseIdentifier)
        
        
        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()
        
        // Style!
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    
    // MARK: - Public Helpers
    public func setupWithSettings(settings: NotificationSettings, streamAtIndex streamIndex: Int) {
        self.settings   = settings
        self.stream     = settings.streams[streamIndex]
        self.newValues  = [String: Bool]()
        
        switch settings.channel {
        case .WordPressCom:
            title = NSLocalizedString("WordPress.com Updates", comment: "WordPress.com Notification Settings Title")
        default:
            title = stream!.kind.description()
        }
        
        tableView.reloadData()
    }
    
    
    // MARK: - UITableView Delegate Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionCount
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings?.sortedPreferenceKeys().count ?? emptyRowCount
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier  = NoteSettingsSwitchTableViewCell.classNameWithoutNamespaces()
        let cell        = tableView.dequeueReusableCellWithIdentifier(identifier) as! NoteSettingsSwitchTableViewCell
        
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    
    // MARK: - UITableView Helpers
    private func configureCell(cell: NoteSettingsSwitchTableViewCell, indexPath: NSIndexPath) {
        let preferences = stream?.preferences
        let key         = settings?.sortedPreferenceKeys()[indexPath.row]
        if preferences == nil || key == nil {
            return
        }
        
        cell.name = settings?.localizedDescription(key!) ?? String()
        cell.isOn = preferences?[key!] ?? true
        cell.onChange = { (newValue: Bool) in
            self.newValues?[key!] = newValue
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
            stream: stream!,
            newValues: newValues!,
            success: nil,
            failure: nil)
    }
    
    
    // MARK: - Private Constants
    private let emptyRowCount   = 0
    private let sectionCount    = 1
    
    // MARK: - Private Properties
    private var settings        : NotificationSettings?
    private var stream          : NotificationSettings.Stream?
    private var newValues       : [String: Bool]?
}
