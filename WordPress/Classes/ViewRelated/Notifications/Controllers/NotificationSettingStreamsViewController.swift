import Foundation


public class NotificationSettingStreamsViewController : UITableViewController
{
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    
    // MARK: - Setup Helpers
    private func setupTableView() {
        // Register the cells
        let reuseIdentifier = NoteSettingsTitleTableViewCell.classNameWithoutNamespaces()
        let switchCellNib   = UINib(nibName: reuseIdentifier, bundle: NSBundle.mainBundle())
        tableView.registerNib(switchCellNib, forCellReuseIdentifier: reuseIdentifier)
        
        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()
        
        // Style!
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    
    // MARK: - Public Helpers
    public func setupWithSettings(settings: NotificationSettings) {
        self.settings = settings
        
        switch settings.channel {
        case let .Site(siteId):
            title = settings.blog?.blogName ?? settings.channel.description()
        case .Other:
            title = NSLocalizedString("Other Sites", comment: "Other Notifications Streams Title")
        default:
            break
        }
        
        tableView.reloadData()
    }
    
    
    // MARK: - UITableView Delegate Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionCount
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings?.streams.count ?? emptyRowCount
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let reuseIdentifier = NoteSettingsTitleTableViewCell.classNameWithoutNamespaces()
        let cell            = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! UITableViewCell
        
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    
    // MARK: - UITableView Delegate Methods
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let identifier  = NotificationSettingDetailsViewController.classNameWithoutNamespaces()
        let streamIndex = indexPath.row
        performSegueWithIdentifier(identifier, sender: streamIndex)
    }
    
    
    // MARK: - UITableView Helpers
    private func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        cell.textLabel?.text = settings?.streams[indexPath.row].kind.description() ?? String()
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    
    // MARK: - Segue Helpers
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let streamsViewController = segue.destinationViewController as? NotificationSettingDetailsViewController,
           let streamIndex = sender as? Int
        {
            streamsViewController.setupWithSettings(settings!, streamAtIndex: streamIndex)
        }
    }
    
    
    // MARK: - Private Constants
    private let emptyRowCount   = 0
    private let sectionCount    = 1

    // MARK: - Private Properties
    private var settings        : NotificationSettings?
}
