import Foundation


public class NotificationSettingStreamsViewController : UITableViewController
{
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    
    // MARK: - UITableView Delegate Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionCount
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Row.Count
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! UITableViewCell
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }

    
    
    // MARK: - UITableView Delegate Methods
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let identifier = NotificationSettingDetailsViewController.classNameWithoutNamespaces()
        performSegueWithIdentifier(identifier, sender: nil)
    }
    
    
    
    // MARK: - UITableView Helpers
    private func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        cell.textLabel?.text = Row(rawValue: indexPath.row)!.description()
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    
    
    // MARK: - Public Helpers
    public func setupWithSiteSettings(settings: [NotificationSettings.Site]) {
        println("Site Settings \(settings)")
    }
    
    public func setupWithOtherSettings(settings: [NotificationSettings.Other]) {
        title = NSLocalizedString("Other Sites", comment: "")
        println("Other Settings \(settings)")
    }
    
    
    
    // MARK: - Table Rows
    private enum Row : Int {
        case Timeline = 0
        case Device
        case Email
        
        func description() -> String {
            switch self {
            case .Timeline:
                return NSLocalizedString("Timeline", comment: "WordPress.com Notifications Timeline")
            case .Device:
                return NSLocalizedString("Push Notifications", comment: "Mobile Push Notifications")
            case .Email:
                return NSLocalizedString("Email", comment: "Email Notifications Channel")
            }
        }
        
        static let Count = 3
    }
    
    private let sectionCount    = 1
    private let reuseIdentifier = "NotificationSettingStreamTableViewCell"
}
