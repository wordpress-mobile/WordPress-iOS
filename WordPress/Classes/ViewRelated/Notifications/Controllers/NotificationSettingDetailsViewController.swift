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
        tableView.registerNib(cellNib, forCellReuseIdentifier: nibName)
    }
    
    
    // MARK: - Public Helpers
    public func setupWithSiteSettings(settings: NotificationSettings.Site) {
println("Site Settings \(settings)")
    }
    
    public func setupWithOtherSettings(settings: NotificationSettings.Other) {
println("Other Settings \(settings)")
    }
    
    public func setupWithWordPressSettings(settings: [NotificationSettings.WordPressCom]) {
println("WordPressCom Settings \(settings)")
    }
    
    
    // MARK: - Private Properties
    private var notificationsService : NotificationsService {
        let mainContext = ContextManager.sharedInstance().mainContext
        return NotificationsService(managedObjectContext: mainContext)
    }
}
