import Foundation


public class NotificationSettingsViewController : UITableViewController
{
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Interface
        setupNavigationItem()
        setupTableView()
        setupSpinner()
        
        // Load Settings
        reloadSettings()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Manually deselect the selected row. This is required due to a bug in iOS7 / iOS8
        tableView.deselectSelectedRowWithAnimation(true)
    }


    // MARK: - Setup Helpers
    private func setupNavigationItem() {
        title = NSLocalizedString("Notifications", comment: "Title displayed in the Notification settings")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .Plain, target: nil, action: nil)
    }
    
    private func setupTableView() {
        // Register the cells
        let reuseIdentifiers = [
            NoteSettingsTitleTableViewCell.classNameWithoutNamespaces(),
            NoteSettingsSubtitleTableViewCell.classNameWithoutNamespaces()
        ]
        
        for reuseIdentifier in reuseIdentifiers {
            let cellNib = UINib(nibName: reuseIdentifier, bundle: NSBundle.mainBundle())
            tableView.registerNib(cellNib, forCellReuseIdentifier: reuseIdentifier)
        }
        
        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()
        
        // Style!
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    private func setupSpinner() {
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicatorView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addSubview(activityIndicatorView)
        view.pinSubviewAtCenter(activityIndicatorView)
    }

    
    
    // MARK: - Service Helpers
    private func reloadSettings() {
        let service = NotificationsService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        
        activityIndicatorView.startAnimating()
        
        service.getAllSettings({ (settings: [NotificationSettings]) in
                self.groupedSettings = self.groupSettings(settings)
                self.activityIndicatorView.stopAnimating()
                self.tableView.reloadData()
            },
            failure: { (error: NSError!) in
// TODO: Handle Error
println("Error \(error)")
            })
    }
    
    private func groupSettings(settings: [NotificationSettings]) -> [[NotificationSettings]] {
        // TODO: Review this whenever we switch to Swift 2.0, and kill the switch filtering. JLP Jul.1.2015
        let siteSettings = settings.filter {
            switch $0.channel {
            case .Blog:
                return true
            default:
                return false
            }
        }
        
        let otherSettings = settings.filter { $0.channel == .Other }
        let wpcomSettings = settings.filter { $0.channel == .WordPressCom }
        
        return [siteSettings, otherSettings, wpcomSettings]
    }



    // MARK: - UITableView Datasource Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return groupedSettings?.count ?? emptyCount
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedSettings?[section].count ?? emptyCount
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let settings    = settingsForRowAtIndexPath(indexPath)!
        let cell        = dequeueCellForSettings(settings, tableView: tableView)
        
        configureCell(cell, settings: settings)
        
        return cell
    }
    
    public override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch settingsForRowAtIndexPath(indexPath)!.channel {
        case let .Blog(blogId):
            return subtitleRowHeight
        default:
            return titleRowHeight
        }
    }
    
    public override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Hack: get rid of the extra top spacing that Grouped UITableView's get, on top
        return CGFloat.min
    }
    
    public override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView      = WPTableViewSectionFooterView(frame: CGRectZero)
        footerView.title    = titleForFooterInSection(section)
        return footerView
    }
    
    public override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let title = titleForFooterInSection(section)
        return WPTableViewSectionFooterView.heightForTitle(title, andWidth: view.frame.width)
    }
    

    // MARK: - UITableView Delegate Methods
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let settings = settingsForRowAtIndexPath(indexPath) {
            displayDetailsForSettings(settings)
        } else  {
            tableView.deselectSelectedRowWithAnimation(true)
        }
    }



    // MARK: - UITableView Helpers
    private func dequeueCellForSettings(settings: NotificationSettings, tableView: UITableView) -> UITableViewCell {
        let identifier : String
        
        switch settings.channel {
        case let .Blog(blogId):
            identifier = NoteSettingsSubtitleTableViewCell.classNameWithoutNamespaces()
        default:
            identifier = NoteSettingsTitleTableViewCell.classNameWithoutNamespaces()
        }
        
        return tableView.dequeueReusableCellWithIdentifier(identifier) as! UITableViewCell
    }
    
    private func configureCell(cell: UITableViewCell, settings: NotificationSettings) {
        switch settings.channel {
        case let .Blog(blogId):
            cell.textLabel?.text        = settings.blog?.blogName ?? settings.channel.description()
            cell.detailTextLabel?.text  = settings.blog?.displayURL ?? String()
            cell.imageView?.setImageWithSiteIcon(settings.blog?.icon)
        default:
            cell.textLabel?.text        = settings.channel.description()
        }
    }
    
    private func settingsForRowAtIndexPath(indexPath: NSIndexPath) -> NotificationSettings? {
        return groupedSettings?[indexPath.section][indexPath.row]
    }
    
    private func titleForFooterInSection(section: Int) -> String {
        switch Section(rawValue: section)! {
        case .Blog:
            return NSLocalizedString("Customize your site settings for Likes, Comments, Follows and more.",
                comment: "Notification Settings for your own blogs")
        case .Other:
            return NSLocalizedString("Control your notification settings when you comment on other blogs",
                comment: "3rd Party Site Notification Settings")
        case .WordPressCom:
            return NSLocalizedString("Decide what emails you get from us regarding your account and sites. " +
                "We'll still send you important emails like password recovery and domain expiration.",
                comment: "WordPress.com Notification Settings")
        }
    }

    
    // MARK: - Segue Helpers
    private func displayDetailsForSettings(settings: NotificationSettings) {
        switch settings.channel {
        case .WordPressCom:
            // WordPress.com Row will push the SettingDetails ViewController, directly
            let detailsViewController = NotificationSettingDetailsViewController()
            detailsViewController.setupWithSettings(settings, streamAtIndex: firstStreamIndex)
            navigationController?.pushViewController(detailsViewController, animated: true)
        default:
            // Our Sites + 3rd Party Sites rows will push the Streams View
            let streamsViewController = NotificationSettingStreamsViewController()
            streamsViewController.setupWithSettings(settings)
            navigationController?.pushViewController(streamsViewController, animated: true)
        }
    }


    // MARK: - Private Constants
    private let titleRowHeight          = CGFloat(44.0)
    private let subtitleRowHeight       = CGFloat(54.0)
    private let emptyCount              = 0
    private let firstStreamIndex        = 0
    
    private enum Section : Int {
        case Blog           = 0
        case Other          = 1
        case WordPressCom   = 2
    }
    
    // MARK: - Private Properties
    private var activityIndicatorView   : UIActivityIndicatorView!
    private var groupedSettings         : [[NotificationSettings]]?
}
