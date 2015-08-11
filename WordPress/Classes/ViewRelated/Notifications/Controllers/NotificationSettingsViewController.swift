import Foundation


/**
*  @class           NotificationSettingsViewController
*  @brief           The purpose of this class is to retrieve the collection of NotificationSettings
*                   from WordPress.com Backend, and render the "Top Level" list.
*                   On Row Press, we'll push the list of available Streams, which will, in turn,
*                   push the Details View itself, which is in charge of rendering the actual available settings.
*/

public class NotificationSettingsViewController : UIViewController
{
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Interface
        setupNavigationItem()
        setupTableView()
        
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
        tableView.registerClass(WPBlogTableViewCell.self, forCellReuseIdentifier: blogReuseIdentifier)
        tableView.registerClass(WPTableViewCell.self, forCellReuseIdentifier: defaultReuseIdentifier)
        
        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()
        
        // Style!
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    
    
    // MARK: - Service Helpers
    private func reloadSettings() {
        let service = NotificationsService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        
        activityIndicatorView.startAnimating()
    
        service.getAllSettings({ [weak self] (settings: [NotificationSettings]) in
                self?.groupedSettings = self?.groupSettings(settings)
                self?.activityIndicatorView.stopAnimating()
                self?.tableView.reloadData()
            },
            failure: { [weak self] (error: NSError!) in
                self?.handleLoadError()
            })
    }
    
    private func groupSettings(settings: [NotificationSettings]) -> [[NotificationSettings]] {
        // Find the Default Blog ID
        let service         = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let defaultAccount  = service.defaultWordPressComAccount()
        let primaryBlogId   = defaultAccount?.defaultBlog?.blogID as? Int
        
        // Proceed Grouping
        var blogSettings    = [NotificationSettings]()
        var otherSettings   = [NotificationSettings]()
        var wpcomSettings   = [NotificationSettings]()
        
        for setting in settings {
            switch setting.channel {
            case let .Blog(blogId):
                // Make sure that the Primary Blog is the first one in its category
                if blogId == primaryBlogId {
                    blogSettings.insert(setting, atIndex: 0)
                } else {
                    blogSettings.append(setting)
                }
            case .Other:
                otherSettings.append(setting)
            case .WordPressCom:
                wpcomSettings.append(setting)
            }
        }
        
        assert(otherSettings.count == 1)
        assert(wpcomSettings.count == 1)
        
        // Sections: Blogs + Other + WpCom
        return [blogSettings, otherSettings, wpcomSettings]
    }

    
    
    // MARK: - Error Handling
    private func handleLoadError() {
        UIAlertView.showWithTitle(NSLocalizedString("Oops!", comment: ""),
            message             : NSLocalizedString("There has been a problem while loading your Notification Settings",
                                                    comment: "Displayed after Notification Settings failed to load"),
            style               : .Default,
            cancelButtonTitle   : NSLocalizedString("Cancel", comment: "Cancel. Action."),
            otherButtonTitles   : [ NSLocalizedString("Try Again", comment: "Try Again. Action") ],
            tapBlock            : { (alertView: UIAlertView!, buttonIndex: Int) -> Void in
                // On Cancel: Let's dismiss this screen
                if alertView.cancelButtonIndex == buttonIndex {
                    self.navigationController?.popViewControllerAnimated(true)
                    return
                }
                
                self.reloadSettings()
            })
    }
    
    
    

    // MARK: - UITableView Datasource Methods
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return groupedSettings?.count ?? emptyCount
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .Blog where displaysLoadMoreRow():
            return loadMoreRowCount
        default:
            return groupedSettings![section].count
        }
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier  = reusableIdentifierForIndexPath(indexPath)
        let cell        = tableView.dequeueReusableCellWithIdentifier(identifier) as! UITableViewCell
        
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch settingsForRowAtIndexPath(indexPath)!.channel {
        case let .Blog(blogId) where !isLoadMoreRow(indexPath):
            return blogRowHeight
        default:
            return WPTableViewDefaultRowHeight
        }
    }
    
    public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Hide when the section is empty!
        if isSectionEmpty(section) {
            return nil
        }
        
        let theSection      = Section(rawValue: section)!
        let footerView      = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Header)
        footerView.title    = theSection.headerText()
        return footerView
    }
    
    public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Hide when the section is empty!
        if isSectionEmpty(section) {
            return CGFloat.min
        }
        
        let theSection      = Section(rawValue: section)!
        let width           = view.frame.width
        return WPTableViewSectionHeaderFooterView.heightForHeader(theSection.headerText(), width: width)
    }
    
    public func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Hide when the section is empty!
        if isSectionEmpty(section) {
            return nil
        }
        
        let theSection      = Section(rawValue: section)!
        let footerView      = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Footer)
        footerView.title    = theSection.footerText()
        
        return footerView
    }
    
    public func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Hide when the section is empty!
        if isSectionEmpty(section) {
            return CGFloat.min
        }
        
        let section         = Section(rawValue: section)!
        let padding         = section.footerPadding()
        let height          = WPTableViewSectionHeaderFooterView.heightForFooter(section.footerText(), width: view.frame.width)

        return height + padding
    }
    

    
    // MARK: - UITableView Delegate Methods
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if isLoadMoreRow(indexPath) {
            displayMoreBlogs()
        } else if let settings = settingsForRowAtIndexPath(indexPath) {
            displayDetailsForSettings(settings)
        } else  {
            tableView.deselectSelectedRowWithAnimation(true)
        }
    }

    

    // MARK: - UITableView Helpers
    private func reusableIdentifierForIndexPath(indexPath: NSIndexPath) -> String {
        switch Section(rawValue: indexPath.section)! {
        case .Blog where !isLoadMoreRow(indexPath):
            return blogReuseIdentifier
        default:
            return defaultReuseIdentifier
        }
    }
    
    private func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        let settings = settingsForRowAtIndexPath(indexPath)!
        
        switch settings.channel {
        case let .Blog(blogId) where isLoadMoreRow(indexPath):
            cell.textLabel?.text            = NSLocalizedString("View all...", comment: "Displays More Rows")
            cell.textLabel?.textAlignment   = .Center
            cell.accessoryType              = .None
            WPStyleGuide.configureTableViewCell(cell)
        case let .Blog(blogId):
            cell.textLabel?.text            = settings.blog?.blogName ?? settings.channel.description()
            cell.detailTextLabel?.text      = settings.blog?.displayURL ?? String()
            cell.accessoryType              = .DisclosureIndicator
            cell.imageView?.setImageWithSiteIcon(settings.blog?.icon)
            WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        default:
            cell.textLabel?.text            = settings.channel.description()
            cell.textLabel?.textAlignment   = .Left
            cell.accessoryType              = .DisclosureIndicator
            WPStyleGuide.configureTableViewCell(cell)
        }
    }
    
    private func settingsForRowAtIndexPath(indexPath: NSIndexPath) -> NotificationSettings? {
        return groupedSettings?[indexPath.section][indexPath.row]
    }
    
    private func isSectionEmpty(sectionIndex: Int) -> Bool {
        return groupedSettings == nil || groupedSettings?[sectionIndex].count == 0
    }
    
    
    
    // MARK: - Load More Helpers
    private func displaysLoadMoreRow() -> Bool {
        return groupedSettings?[Section.Blog.rawValue].count > loadMoreRowIndex && !displayMoreWasAccepted
    }
    
    private func isLoadMoreRow(indexPath: NSIndexPath) -> Bool {
        if displaysLoadMoreRow() {
            return indexPath.section == Section.Blog.rawValue && indexPath.row == loadMoreRowIndex
        }
        
        return false
    }
    
    private func displayMoreBlogs() {
        // Remember this action!
        displayMoreWasAccepted = true
        
        // And refresh the section
        let sections = NSIndexSet(index: Section.Blog.rawValue)
        tableView.reloadSections(sections, withRowAnimation: .Fade)
    }

    
    
    // MARK: - Segue Helpers
    private func displayDetailsForSettings(settings: NotificationSettings) {
        switch settings.channel {
        case .WordPressCom:
            // WordPress.com Row will push the SettingDetails ViewController, directly
            let detailsViewController = NotificationSettingDetailsViewController(style: .Grouped)
            detailsViewController.setupWithSettings(settings, stream: settings.streams.first!)
            navigationController?.pushViewController(detailsViewController, animated: true)
        default:
            // Our Sites + 3rd Party Sites rows will push the Streams View
            let streamsViewController = NotificationSettingStreamsViewController(style: .Grouped)
            streamsViewController.setupWithSettings(settings)
            navigationController?.pushViewController(streamsViewController, animated: true)
        }
    }
    
    
    
    // MARK: - Table Sections
    private enum Section : Int {
        case Blog           = 0
        case Other          = 1
        case WordPressCom   = 2
        
        func headerText() -> String {
            switch self {
            case .Blog:
                return NSLocalizedString("Your Sites",
                    comment: "Displayed in the Notification Settings View")
            case .Other:
                return NSLocalizedString("Comments on Other Sites",
                    comment: "Displayed in the Notification Settings View")
            case .WordPressCom:
                return NSLocalizedString("WordPress.com Updates",
                    comment: "Displayed in the Notification Settings View")
            }
        }
        
        func footerText() -> String {
            switch self {
            case .Blog:
                return NSLocalizedString("Customize your site settings for Likes, Comments, Follows, and more.",
                    comment: "Notification Settings for your own blogs")
            case .Other:
                return NSLocalizedString("Notification settings for your comments on other sites.",
                    comment: "3rd Party Site Notification Settings")
            case .WordPressCom:
                return NSLocalizedString("We’ll always send important emails regarding your account, " +
                    "but you can get some fun extras, too!",
                    comment: "Title displayed in the Notification Settings for WordPress.com")
            }
        }
        
        func footerPadding() -> CGFloat {
            switch self {
            case .WordPressCom:
                return UIDevice.isPad() ? Section.paddingWordPress : Section.paddingZero
            default:
                return Section.paddingZero
            }
        }
        
        // MARK: - Private Constants
        private static let paddingZero      = CGFloat(0)
        private static let paddingWordPress = CGFloat(40)
    }
    
    
    
    // MARK: - Private Outlets
    @IBOutlet private var tableView             : UITableView!
    @IBOutlet private var activityIndicatorView : UIActivityIndicatorView!
    
    // MARK: - Private Constants
    private let blogReuseIdentifier             = WPBlogTableViewCell.classNameWithoutNamespaces()
    private let blogRowHeight                   = CGFloat(54.0)
    
    private let defaultReuseIdentifier          = WPTableViewCell.classNameWithoutNamespaces()
    
    private let emptyCount                      = 0
    private let loadMoreRowIndex                = 3
    private let loadMoreRowCount                = 4
    
    // MARK: - Private Properties
    private var groupedSettings                 : [[NotificationSettings]]?
    private var displayMoreWasAccepted          = false
}
