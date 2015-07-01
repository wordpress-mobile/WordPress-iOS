import Foundation


public class NotificationSettingDetailsViewController : UITableViewController
{
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        registerCellNibs()
    }

    
    // MARK: - Setup Helpers
    private func registerCellNibs() {
        let nibName = NoteSettingsTableViewCell.classNameWithoutNamespaces()
        let cellNib = UINib(nibName: nibName, bundle: NSBundle.mainBundle())
        tableView.registerNib(cellNib, forCellReuseIdentifier: reuseIdentifier)
    }
    
    
    // MARK: - Public Helpers
    public func setupWithSettings(settings: NotificationSettings, streamAtIndex streamIndex: Int) {
        self.settings = settings
        self.stream = settings.streams[streamIndex]
        
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
        return stream?.preferences?.count ?? emptyRowCount
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! NoteSettingsTableViewCell
        
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    
    // MARK: - UITableView Helpers
    private func configureCell(cell: NoteSettingsTableViewCell, indexPath: NSIndexPath) {
// TODO: Localized and Sorted Preferences
        let preferences = stream?.preferences
        if preferences == nil {
            return
        }
        
        let key     = preferences?.keys.array[indexPath.row] ?? String()
        let value   = preferences?[key] ?? true
        
        cell.textLabel?.text = key
        
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    
    // MARK: - Private Constants
    private let emptyRowCount   = 0
    private let sectionCount    = 1
    private let reuseIdentifier = NoteSettingsTableViewCell.classNameWithoutNamespaces()
    
    // MARK: - Private Properties
    private var settings        : NotificationSettings?
    private var stream          : NotificationSettings.Stream?
}
