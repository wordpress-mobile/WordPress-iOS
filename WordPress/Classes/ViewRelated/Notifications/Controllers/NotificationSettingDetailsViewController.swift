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
    public func loadBlogSettings(blogId: Int?) {
        if blogId == nil {
            return
        }

        notificationsService.getSiteSettings(blogId!,
            success: { (settings: [NotificationSettings.Site]) in

            },
            failure: { (error: NSError!) in

            })
    }
    
    public func loadOtherSettings() {
        notificationsService.getOtherSettings({ (settings: [NotificationSettings.Other]) in

            },
            failure: { (error: NSError!) in

            })
    }
    
    public func loadWordPressSettings() {
        notificationsService.getWordPressComSettings({ (wpcom: NotificationSettings.WordPressCom) in

            },
            failure: { (error: NSError!) in

            })
    }
    
    
    // MARK: - Private Properties
    private var notificationsService : NotificationsService {
        let mainContext = ContextManager.sharedInstance().mainContext
        return NotificationsService(managedObjectContext: mainContext)
    }
}
